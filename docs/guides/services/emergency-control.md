# If the smart home stops working (Emergency Control)

**Works:** at home only, on the house Wi-Fi.

Normally you control the lights, heating and appliances from the **Home Assistant** app. Sometimes Home Assistant is down, or the part of the system that talks to the Zigbee devices (**Zigbee2MQTT**) is down. When that happens the app may not open, the buttons do nothing, or devices show as **unavailable**.

Don't worry. Every phone in the house also has a second app called **Emergency Control**. It sends the on/off commands straight to the lights, the boiler, the dishwasher and the other devices, without going through Home Assistant at all.

## When to use it

Use Emergency Control when:

- the Home Assistant app won't open or says it can't connect, or
- a light, the heating or an appliance won't respond from Home Assistant, and several other things are not responding either. (The [status page](../help/status.md) shows when Home Assistant itself is down.)

If only one thing isn't responding and everything else works, try [Troubleshooting](../help/troubleshooting.md) first.

## How to use it

1. Make sure your phone is on the **house Wi-Fi**.
2. Open the **Emergency Control** app.
3. Find the thing you want to control. The buttons are named after the lights, heating and appliances.
4. Tap the button once, and wait a couple of seconds.

## If it doesn't work

- Check you are on the house Wi-Fi, not mobile data or the guest network.
- Tap the button once more and wait.
- Still nothing? Tell Scott which button you tapped.

## Good to know

- This is for emergencies. It switches things on and off, but it doesn't run schedules or automations, so things that normally happen on their own (such as lights coming on at sunset) won't happen while Home Assistant is down.
- Home Assistant may not know what you changed while it was down. It should catch up when it is working again.
- Please tell Scott as soon as you reach for this app, so he can fix the cause.
