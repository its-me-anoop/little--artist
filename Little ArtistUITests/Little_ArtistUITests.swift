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
    private func launchApp(showOnboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]
        if showOnboarding {
            app.launchArguments += ["-uiTestShowOnboarding"]
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

    // MARK: - Main Navigation

    func testAllTabsNavigate() throws {
        let app = launchApp()
        let tabBar = waitForMainTabs(app)

        tabBar.buttons["Timeline"].tap()
        tabBar.buttons["Milestones"].tap()
        XCTAssertTrue(app.staticTexts["First Masterpiece"].waitForExistence(timeout: 10),
                      "Seeded achievements should be visible on the Milestones tab")

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

    func testCreateChildThenSecondChildHitsPaywall() throws {
        let app = launchApp()
        waitForMainTabs(app)

        // Create the first (free-tier) child.
        app.buttons["Add artwork"].tap()
        let nameField = app.textFields["Child's name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Mia")
        // Scope to the sheet's scroll view — the software keyboard can
        // expose an identically-labelled key element.
        app.scrollViews.buttons["Add Child"].firstMatch.tap()

        // A second child is over the free limit — Settings Add New shows the paywall.
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Settings"].tap()
        let addNew = app.buttons["Add New"]
        XCTAssertTrue(addNew.waitForExistence(timeout: 10))
        addNew.tap()

        XCTAssertTrue(app.staticTexts["Unlock Your Full Studio"].waitForExistence(timeout: 10),
                      "Second child on the free tier should hit the paywall")
    }

    // MARK: - Paywall

    func testPaywallShowsAllThreePlans() throws {
        let app = launchApp()
        waitForMainTabs(app)

        // Create a child, then trigger the paywall via Settings → Add New.
        app.buttons["Add artwork"].tap()
        let nameField = app.textFields["Child's name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Noah")
        // Scope to the sheet's scroll view — the software keyboard can
        // expose an identically-labelled key element.
        app.scrollViews.buttons["Add Child"].firstMatch.tap()

        app.tabBars.firstMatch.buttons["Settings"].tap()
        let addNew = app.buttons["Add New"]
        XCTAssertTrue(addNew.waitForExistence(timeout: 10))
        addNew.tap()

        XCTAssertTrue(app.staticTexts["Yearly"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Monthly"].exists)
        XCTAssertTrue(app.staticTexts["Lifetime"].exists)
        XCTAssertTrue(app.buttons["Restore Purchases"].exists)
    }
}
