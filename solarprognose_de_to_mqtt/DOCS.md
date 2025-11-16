# Home Assistant Community Add-on: Solarprognose.de to MQTT

This is an Home Assistant add-on for request forecast data from [solarprognose.de](https://www.solarprognose.de). When started, it will make one initial request with setted parameters. After first request data will be requested periodically in setted interval. Request will Syncronized with service information from solarprognose.de for Second of Hour time value.
The Add-On is Based on Community Add-Ons [Example](https://github.com/hassio-addons/addon-example)

## Installation

1. Add Repository to your Home Assistant. 
1. Click the Home Assistant My button below to open the add-on on your Home
   Assistant instance.

   [![Open this add-on in your Home Assistant instance.][addon-badge]][addon]

1. Click the "Install" button to install the add-on.
1. Start the Add-on.
1. Check the logs of the add-on to see it in action.

## Configuration

Configure the Add-On like documentation on [solarprognose.de-API](https://www.solarprognose.de/web/de-de/solarprediction/page/api) page.

## Donation

If you want to give a little tip for support it will be the best to support the developer from solarprognose.de. Please klick on this [Link](https://www.solarprognose.de/web/de-de/plan/order/donate). 

If you want to say thanks for the Add-On you can send an coffee-tip to [me](http://paypal.me/cappuccinokasse).

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```yaml
log_level: info
accesstoken: "*your_access_token*"
project: "*your_mail_adress*"
type: daily
algorithm: own-v1
MQTT_HOST: "localhost"
MQTT_USER: "mqtt"
MQTT_PASSWORD: "mqtt"
MQTT_TOPIC: "solarprognose"
break_time: 1
```

### Option: `log_level`

The `log_level` option controls the level of log output by the add-on and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`: Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

### Option: `accesstoken`

Sets the Access-Token for Solarprognose.de.

### Option: `project`

Sets your Website or your mail. So the page-owner will contact you if nessesary.

### Option: `item`

Sets "location" or "plant" or "inverter" or "module_field" for requesting by id.

### Option: `id`

Sets the unique number to select an item. The first option is using a combination of item and id.

### Option: `token`

Sets the Token to access privat elements. If you only have one location you don´t need item/id/token, the API is responsing data from first location. ITEM und TOKEN is nessasary to access elements witch are not public "&item=inverter&token=" If you got access by access-token you can get data from privat elements.

### Option: `type`

Sets the time based request type.

### Option: `algorithm`

Sets the Algorithm for calculate forcast data.

### Option: `day`

Sets the first day in the forcast data in relation to actual day from -2 up to 6. It will start with selected day up to your normal forcast interval. Note: This may be limited by your subscription plan! The error "STATUS_ERROR_INVALID_DAY" may occur if the value exceeds what your plan includes. Use this option or Options `start_day` and `end_day`.

### Option: `start_day`

Sets the first day in the forcast data in relation to actual day from -2 up to 6. It will start with selected day up to your normal forcast interval. Note: This may be limited by your subscription plan! The error "STATUS_ERROR_INVALID_START_DAY" may occur if the value exceeds what your plan includes. Use this option wit Option `end_day` or Option `day`.

### Option: `end_day`

Sets the last day in the forcast data in relation to actual day from -2 up to 6. It will start with selected day up to your normal forcast interval. Note: This may be limited by your subscription plan! The error "STATUS_ERROR_INVALID_END_DAY" may occur if the value exceeds what your plan includes. Use this option wit Option `start_day` or Option `day`.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality.

Releases are based on [Semantic Versioning][semver], and use the format
of `MAJOR.MINOR.PATCH`. In a nutshell, the version will be incremented
based on the following:

- `MAJOR`: Incompatible or major changes.
- `MINOR`: Backwards-compatible new features and enhancements.
- `PATCH`: Backwards-compatible bugfixes and package updates.

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Community Add-ons Discord chat server][discord] for add-on
  support and feature requests.
- The [Home Assistant Discord chat server][discord-ha] for general Home
  Assistant discussions and questions.
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

You could also [open an issue here][issue] GitHub.

## Authors & contributors

The original setup of this repository is by [Franck Nijhof][frenck].

For a full list of all authors and contributors,
check [the contributor's page][contributors].

## License

MIT License

Copyright (c) 2017-2025 Franck Nijhof

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[addon-badge]: https://my.home-assistant.io/badges/supervisor_addon.svg
[addon]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=solarprognose_de_to_mqtt&repository_url=https%3A%2F%2Fgithub.com%2Fphotomax2202%2Fha-plugins
[contributors]: https://github.com/hassio-addons/addon-example/graphs/contributors
[discord-ha]: https://discord.gg/c5DvZ4e
[discord]: https://discord.me/hassioaddons
[forum]: https://community.home-assistant.io/t/repository-community-hass-io-add-ons/24705?u=frenck
[frenck]: https://github.com/frenck
[issue]: https://github.com/photomax2202/ha-plugins/issues
[reddit]: https://reddit.com/r/homeassistant
[releases]: https://github.com/photomax2202/ha-plugins/releases
[semver]: http://semver.org/spec/v2.0.0.html
