# Smart home (Home Assistant)

**Address:** <https://home.f9.casa>

Home Assistant is the brain of the house. It connects the lights, heating, cameras, locks, appliances and speakers, which would otherwise each need their own app, and lets them work together.

## What it does in our home

- **Heating and hot water.** Every room has its own thermostat or radiator valve with a weekly schedule. Home Assistant also talks to the boiler, so it can decide when to fire it, and you can give a room a one-hour **boost** when you're cold.
- **Lights and plugs.** Control them from your phone, by voice or with wall buttons. Some switch on by themselves, for example with motion in the hallway or bathroom, or when the understairs cupboard door opens.
- **Cameras and doorbell.** The doorbell and the front, back, side and garage cameras are available in Home Assistant. It notices people, vehicles and animals and can send you a notification.
- **Doors and garage.** See whether the front door is locked and the garage door is closed.
- **Appliances.** The washing machine, tumble dryer and dishwasher tell you when they've finished, with a "ready to unload" reminder until someone empties them.
- **Robot vacuum.** Start it, send it to a room and see when it has finished.
- **3D printer.** Print progress, and a "ready to collect" alert when a print is done.
- **Energy.** It tracks electricity and gas use and our Octopus tariff, including free-electricity and saving sessions.
- **Voice.** Talk to the Echo Dot in the lounge or the kitchen screen. The kitchen screen's assistant runs on our own local AI.
- **Phones and presence.** The app tells the house who is home, so heating and lights can react.
- **Chores and lists.** The shopping list and the chore tracker (ChoreOps) live here too.
- **Safety alerts.** Leak sensors, wind alerts and low-battery warnings send notifications to phones.
- **Bin day.** The waste collection calendar tells you which bins go out.

## On your phone

1. Install the **Home Assistant** app:

<p class="store-badges">
<a href="https://apps.apple.com/app/id1099568401"><img src="../../assets/badges/app-store.svg" alt="Download on the App Store"></a>
<a href="https://play.google.com/store/apps/details?id=io.homeassistant.companion.android"><img src="../../assets/badges/google-play.png" alt="Get it on Google Play"></a>
</p>

2. When asked for the server address, enter `https://home.f9.casa`.
3. Sign in.

Using the app also lets the house know when you're home, which some automations use.

## Automations

Lots of things happen automatically, such as lights switching on at dusk. If something does something unexpected, tell Scott rather than changing settings.

!!! warning "Please don't edit automations"
    Changing automations or settings can break things for everyone. Dashboards and device controls are safe to use.
