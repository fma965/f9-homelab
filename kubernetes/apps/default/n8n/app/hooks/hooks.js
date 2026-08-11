module.exports = {
  n8n: {
    ready: [
      async function ({ app }, config) {
        const { dirname, resolve } = require("path");
        const { randomBytes } = require("crypto");
        const { hash } = require("bcryptjs");
        const { issueCookie } = require(resolve(
          dirname(require.resolve("n8n")),
          "auth/jwt"
        ));

        // Trust the proxy for correct X-Forwarded-* handling and rate limiting
        app.set("trust proxy", 1);

        const ignoreAuth =
          /^\/(assets|healthz|webhook|rest\/oauth2-credential|health)/;
        const cookieName = "n8n-auth";

        const UserRepo = this.dbCollections.User;
        const RoleRepo = this.dbCollections.Role;

        const { stack } = app.router;
        const idx = stack.findIndex((l) => l?.name === "cookieParser");

        // Derive the Layer class from an existing router-stack entry (every
        // entry is a Layer instance). This is version-independent and avoids
        // requiring the internal "router/lib/layer" module path, which is not
        // resolvable from /hooks and was removed in the router version bundled
        // with newer n8n images (>= 2.30.x).
        const Layer = (stack[idx] ?? stack[0]).constructor;

        const layer = new Layer(
          "/",
          { strict: false, end: false },
          async (req, res, next) => {
            try {
              // Skip if URL matches ignore list
              if (ignoreAuth.test(req.url)) return next();

              // Skip until instance owner setup is complete
              if (!config.get("userManagement.isInstanceOwnerSetUp", false))
                return next();

              // Skip if auth cookie already present
              if (req.cookies?.[cookieName]) return next();

              // X-authentik-username,X-authentik-groups,X-authentik-entitlements,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version
              // Read email and optional names from headers/JWT
              const emailHeader = req.headers["x-authentik-email"];
              const authHeader = req.headers["x-authentik-jwt"] || "";
              let firstName = req.headers["x-authentik-name"] || "";
              let lastName = "";

              // Try to extract given/family names from JWT payload
              if (authHeader) {
                try {
                  const token = String(authHeader).replace(/^Bearer\s+/i, "");
                  const parts = token.split(".");
                  if (parts.length === 3) {
                    const payload = JSON.parse(
                      Buffer.from(parts[1], "base64").toString()
                    );
                    firstName = payload.given_name || payload.firstName || "";
                    lastName = payload.family_name || payload.lastName || "";
                    this.logger?.debug(
                      `Extracted from JWT: firstName="${firstName}", lastName="${lastName}"`
                    );
                  }
                } catch (e) {
                  this.logger?.debug(`Failed to decode JWT: ${e.message}`);
                }
              }

              const userEmail = Array.isArray(emailHeader)
                ? emailHeader[0]
                : String(emailHeader).trim();
              const userFirstName = Array.isArray(firstName)
                ? firstName[0]
                : String(firstName).trim();
              const userLastName = Array.isArray(lastName)
                ? lastName[0]
                : String(lastName).trim();

              this.logger?.info(
                `SSO auto-login attempt for email: ${userEmail}`
              );

              // 1) Try to fetch the user including the 'role' relation (needed by n8n 1.112.6)
              let user = await UserRepo.findOne({
                where: { email: userEmail },
                relations: ["role"],
              });

              // 2) If not found — create the user (with 'global:member' role) and a project
              if (!user) {
                const hashed = await hash(randomBytes(16).toString("hex"), 10);

                const userData = {
                  email: userEmail,
                  role: "global:member", // string-based role is valid for createUserWithProject
                  password: hashed,
                  firstName: firstName,
                  lastName: lastName,
                };

                const created = await UserRepo.createUserWithProject(userData);
                user = created.user;

                this.logger?.info(
                  `Created new user: ${userEmail} (${userFirstName} ${userLastName}) via SSO`
                );
              } else {
                // 3) Update first/last name if they changed upstream
                let changed = false;
                if (userFirstName && user.firstName !== userFirstName) {
                  user.firstName = userFirstName;
                  changed = true;
                }
                if (userLastName && user.lastName !== userLastName) {
                  user.lastName = userLastName;
                  changed = true;
                }
                if (changed) {
                  await UserRepo.save(user);
                  this.logger?.info(
                    `Updated user: ${userEmail} (${userFirstName} ${userLastName}) via SSO`
                  );
                } else {
                  this.logger?.info(
                    `Existing user logged in: ${userEmail} via SSO`
                  );
                }
              }

              // 4) Ensure 'user.role' exists (critical in 1.112.6, which dereferences role.slug)
              if (!user.role) {
                // Try to load by roleId
                if (user.roleId && RoleRepo) {
                  user.role = await RoleRepo.findOneBy({ id: user.roleId });
                } else {
                  // As a last resort, reload the user with relations
                  const reloaded = await UserRepo.findOne({
                    where: { id: user.id },
                    relations: ["role"],
                  });
                  if (reloaded) user = reloaded;
                }
              }

              if (!user.role || !user.role.slug) {
                // Without a valid role cookie issuance will crash on 1.112.6
                this.logger?.error(
                  `User ${userEmail} has no valid role; cannot issue cookie.`
                );
                res.statusCode = 401;
                res.end(
                  `User ${userEmail} has no valid role. Ask admin to assign a role.`
                );
                return;
              }

              // 5) Issue n8n auth cookie (alt: this.auth.issueCookie(res, user, project))
              issueCookie(res, user);

              // 6) Attach context for downstream middleware/routes
              req.user = user;
              req.userId = user.id;

              return next();
            } catch (error) {
              this.logger?.error(`SSO middleware error: ${error.message}`);
              return next(error);
            }
          }
        );

        // Insert our middleware right after cookieParser
        stack.splice(idx + 1, 0, layer);
        this.logger?.info("SSO middleware initialized successfully");

        // Logout endpoint: clear n8n cookie and redirect to your IdP logout
        app.get("/logout", (req, res) => {
          this.logger?.info("User logout initiated");
          res.clearCookie(cookieName, { path: "/" });
          res.redirect(
            "/oauth2/sign_out?rd=http://localhost:8080/realms/demo/protocol/openid-connect/logout"
          );
        });
      },
    ],
  },
};