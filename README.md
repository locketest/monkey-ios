# monkey-ios
Monkey's iOS app.

## Getting Started
1. Clone [this repository](https://github.com/holla-world/monkey-ios) by clicking the green "Clone or Download" button above and then "Open in Desktop" to open in the GitHub Desktop app. If you don't have the GitHub Desktop app, download it and repeat this step.

   For advanced users, `git clone git@github.com:holla-world/monkey-api.git` or `git clone https://github.com/holla-world/monkey-api.git` in Terminal.
 
2. `cd` into the project directory by opening Terminal.app, typing `cd`, dragging the monkey-ios folder you downloaded in step 1 onto the Terminal window, and then press return.

3. Install Cocoapods if you don't already have it by typing `sudo gem install cocoapods` into Terminal and pressing return. You may need to enter your password.

4. Install the Monkey iOS app dependencies using `pod install`.

5. Open the `xcworkspace` file in the project folder (do not open the `xcodeproj` file).

6. Press `Command-Shift-K` on your keyboard to clean the project.

7. Connect your device and run the app using `Command-R`.

Switch between the build schemas:
- "Sandbox" - Pink Monkey - for testing API code under active development.
- "Development" - Pink Monkey - for testing the app in an isolated environment.
- "Production" - Pink Monkey - for testing the app with real users.
- "Release" - Blue Monkey - for testing the app by updating the App Store app on your phone to the new development version.
