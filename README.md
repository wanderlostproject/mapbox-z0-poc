# mapbox-z0-poc

You will need an API running to emulate tile responses and enable you to observe tile requests

1. cd api
1. npm install
1. npm start

to test that the api is running
```curl http://localhost:3000```
And you should see hello world

Next you will need to get the mobile app set up:

1. Ensure Xcode 9.4+ is installed
1. In Xcode, Preferences -> Locations -> select most recent Command Line Tools
1. Install CocoaPods: `sudo gem install cocoapods -v 1.9.3` (see https://github.com/react-native-mapbox-gl/maps/issues/1097)
1. In the `swift-app` folder: `pod install`

Then run the mobile app from xcode:

1. Launch Xcode and open `mapbox-swift-poc.xcworkspace`
1. Set `MGLMapboxAccessToken` string in `Info.plist` file
1. Select a simulator and run the application

Then you will see a UI with a bunch of buttons.

1. Click "Reset" to ensure database is in a clean state
1. Click "Download z0"

    > observe 500+ features downloaded in xcode log (expected 1 tile)

    > observe a z9 tile download in api log (expected only z0 tiles requested)
