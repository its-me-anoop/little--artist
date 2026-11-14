//
//  Little_ArtistUITests.swift
//  Little ArtistUITests
//
//  UI smoke tests covering launch, onboarding, tab navigation, the
//  create flow, free-tier gating, and Settings. The app runs with an
//  in-memory store via the -uiTesting launch argument so every test
//  starts from a clean, deterministic state.
//

import XCTest

final class Little_ArtistUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app in UI-test mode (in-memory store, onboarding
    /// pre-completed unless `showOnboarding` is true).
    private func launchApp(
        showOnboarding: Bool = false,
        sampleArtwork: Bool = false,
        access: String = "trial"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-uiTestAccess", access]
        if showOnboarding {
            app.launchArguments += ["-uiTestShowOnboarding"]
        }
        if sampleArtwork {
            app.launchArguments += ["-uiTestSeedSampleArtwork"]
        }
        app.launch()
        return app
    }

    /// Waits out the splash video until the main tab bar appears.
    @discardableResult
    private func waitForMainTabs(_ app: XCUIApplication) -> XCUIElement {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 30), "Main tab bar never appeared")
        return tabBar
    }

    // MARK: - Onboarding

    func testOnboardingAppearsAndSkipLeadsToMainApp() throws {
        let app = launchApp(showOnboarding: true)

        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 30), "Onboarding Skip button never appeared")

        // Give the page video/entrance animation a beat, then capture a
        // store-listing screenshot.
        Thread.sleep(forTimeInterval: 2)
        let onboardingShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        onboardingShot.name = "onboarding"
        onboardingShot.lifetime = .keepAlways
        add(onboardingShot)

        skip.tap()
        waitForMainTabs(app)
    }

    func testOnboardingGetStartedOpensAddChild() throws {
        let app = launchApp(showOnboarding: true)

        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 30))

        // Advance through all five pages.
        for _ in 0..<4 {
            app.buttons["Next"].tap()
        }

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        // With no children, Get Started opens the Add Child sheet.
        XCTAssertTrue(app.textFields["Child's name"].waitForExistence(timeout: 10))
    }

    func testOnboardingGetStartedOffersTrialFirst() throws {
        let app = launchApp(showOnboarding: true, access: "notStarted")

        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 30))
        for _ in 0..<4 {
            app.buttons["Next"].tap()
        }
        app.buttons["Get Started"].tap()

        // Before the trial is started, Get Started offers it.
        XCTAssertTrue(app.buttons["Start 30-Day Free Trial"].waitForExistence(timeout: 10))
    }

    // MARK: - Main Navigation

    func testAllTabsNavigate() throws {
        let app = launchApp()
        let tabBar = waitForMainTabs(app)

        tabBar.buttons["Timeline"].tap()
        tabBar.buttons["Milestones"].tap()
        XCTAssertTrue(app.staticTexts["First Masterpiece"].waitForExistence(timeout: 10),
                      "Seeded achievements should be visible on the Milestones tab")

        // Store-listing screenshot of the milestones screen.
        Thread.sleep(forTimeInterval: 1)
        let milestonesShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        milestonesShot.name = "milestones"
        milestonesShot.lifetime = .keepAlways
        add(milestonesShot)

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["iCloud Sync"].waitForExistence(timeout: 10),
                      "Settings should show the iCloud Sync row")

        tabBar.buttons["Gallery"].tap()
    }

    // MARK: - Create Flow

    func testAddFlowOpensAddChildWhenNoChildren() throws {
        let app = launchApp()
        waitForMainTabs(app)

        app.buttons["Add artwork"].tap()
        XCTAssertTrue(app.textFields["Child's name"].waitForExistence(timeout: 10),
                      "FAB should open Add Child when no children exist")
    }

    func testUnlimitedChildrenDuringTrial() throws {
        let app = launchApp(access: "trial")
        waitForMainTabs(app)

        // First child from the add button (no children yet).
        app.buttons["Add artwork"].tap()
        addChild(named: "Mia", in: app)

        // Second and third children from Settings: no limit during the trial.
        app.tabBars.firstMatch.buttons["Settings"].tap()
        for name in ["Leo", "Zoe"] {
            let addNew = app.buttons["Add New"]
            XCTAssertTrue(addNew.waitForExistence(timeout: 10))
            addNew.tap()
            addChild(named: name, in: app)
        }
    }

    /// Fills in and saves the Add Child sheet.
    private func addChild(named name: String, in app: XCUIApplication) {
        let nameField = app.textFields["Child's name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10),
                      "Adding \(name) must open Add Child, not a paywall")
        nameField.tap()
        nameField.typeText(name)
        // Scope to the sheet's scroll view — the software keyboard can
        // expose an identically-labelled key element.
        app.scrollViews.buttons["Add Child"].firstMatch.tap()
        XCTAssertTrue(nameField.waitForNonExistence(timeout: 10))
    }

    // MARK: - Paywall

    func testTrialOfferShownBeforeTrialStarts() throws {
        let app = launchApp(access: "notStarted")
        waitForMainTabs(app)

        app.buttons["Add artwork"].tap()

        XCTAssertTrue(app.buttons["Start 30-Day Free Trial"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Restore Purchases"].exists)
        // Guideline 3.1.1: length, what happens after and price disclosed up front.
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Free for 30 days'")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Your art stays yours'")).firstMatch.exists)

        // Capture the paywall for App Store Connect IAP review screenshots.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "paywall-trial"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLifetimeOfferAfterTrialEnds() throws {
        let app = launchApp(sampleArtwork: true, access: "expired")
        waitForMainTabs(app)

        app.buttons["Add artwork"].tap()

        XCTAssertTrue(app.staticTexts["Your free month has ended"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Start 30-Day Free Trial"].exists, "The trial can only be used once")
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Unlock Lifetime'")).firstMatch.exists)
    }

    // MARK: - Growth Features

    func testSettingsOffersFreeExportAndRating() throws {
        let app = launchApp(sampleArtwork: true)
        waitForMainTabs(app)

        app.tabBars.firstMatch.buttons["Settings"].tap()
        let export = app.buttons["exportEverythingButton"]
        XCTAssertTrue(export.waitForExistence(timeout: 10), "Export Everything row missing")
        XCTAssertTrue(export.isEnabled, "Export Everything must be free (enabled without Premium)")

        export.tap()
        XCTAssertTrue(app.buttons["Download Archive (ZIP)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Save All Images to Photos"].exists)
        // iOS 26 presents the dialog as a popover without a Cancel button.
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].firstMatch.tap()
        } else {
            app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        }

        XCTAssertTrue(app.links["Rate Little Artist"].waitForExistence(timeout: 5)
                      || app.buttons["Rate Little Artist"].exists)
    }

    // MARK: - Store Screenshots

    /// Captures App Store screenshots with a gallery full of sample artwork.
    /// Run on the 6.9" iPhone and 13" iPad simulators and export the
    /// attachments from the test report.
    func testCaptureStoreScreenshotsWithSampleArtwork() throws {
        let app = launchApp(sampleArtwork: true)
        let tabBar = waitForMainTabs(app)

        func capture(_ name: String) {
            Thread.sleep(forTimeInterval: 1.5)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }

        capture("01-gallery")

        tabBar.buttons["Timeline"].tap()
        capture("02-timeline")

        tabBar.buttons["Milestones"].tap()
        capture("03-milestones")

        tabBar.buttons["Gallery"].tap()
        let firstArtwork = app.scrollViews.images.firstMatch
        if firstArtwork.waitForExistence(timeout: 5) {
            firstArtwork.tap()
            capture("04-artwork-detail")
            app.navigationBars.buttons.firstMatch.tap()
        }

        tabBar.buttons["Settings"].tap()
        capture("05-settings-export")
    }
}
