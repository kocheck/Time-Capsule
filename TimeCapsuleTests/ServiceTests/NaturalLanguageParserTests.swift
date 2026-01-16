import Testing
import Foundation
@testable import TimeCapsule

@Suite("NaturalLanguageParser Tests")
struct NaturalLanguageParserTests {

    let parser = NaturalLanguageParser()

    // MARK: - Basic Title Extraction

    @Test("Extracts simple task title")
    func testSimpleTitle() {
        let result = parser.parse("Buy groceries")

        #expect(result.title == "Buy groceries")
    }

    @Test("Removes 'remind me to' prefix")
    func testRemindMeToPrefix() {
        let result = parser.parse("Remind me to call mom")

        #expect(result.title == "Call mom")
    }

    @Test("Removes 'I need to' prefix")
    func testINeedToPrefix() {
        let result = parser.parse("I need to finish the report")

        #expect(result.title == "Finish the report")
    }

    @Test("Removes 'don't forget to' prefix")
    func testDontForgetToPrefix() {
        let result = parser.parse("Don't forget to send the email")

        #expect(result.title == "Send the email")
    }

    // MARK: - Priority Extraction

    @Test("Detects high priority from 'urgent'")
    func testUrgentPriority() {
        let result = parser.parse("Urgent: Submit tax returns")

        #expect(result.priority == .high)
    }

    @Test("Detects high priority from 'ASAP'")
    func testAsapPriority() {
        let result = parser.parse("Call the client ASAP")

        #expect(result.priority == .high)
    }

    @Test("Detects high priority from 'important'")
    func testImportantPriority() {
        let result = parser.parse("Important meeting with boss")

        #expect(result.priority == .high)
    }

    @Test("Detects low priority from 'sometime'")
    func testSometimePriority() {
        let result = parser.parse("Organize closet sometime")

        #expect(result.priority == .low)
    }

    @Test("Detects low priority from 'when I have time'")
    func testWhenIHaveTimePriority() {
        let result = parser.parse("Read that book when I have time")

        #expect(result.priority == .low)
    }

    @Test("Defaults to normal priority")
    func testDefaultPriority() {
        let result = parser.parse("Buy groceries")

        #expect(result.priority == .normal)
    }

    // MARK: - Time of Day Context

    @Test("Extracts morning context")
    func testMorningContext() {
        let result = parser.parse("Go for a run in the morning")

        #expect(result.contextHints.contains("morning"))
    }

    @Test("Extracts evening context")
    func testEveningContext() {
        let result = parser.parse("Call mom in the evening")

        #expect(result.contextHints.contains("evening"))
    }

    @Test("Extracts 'tonight' as evening")
    func testTonightContext() {
        let result = parser.parse("Watch movie tonight")

        #expect(result.contextHints.contains("evening"))
    }

    @Test("Extracts afternoon context")
    func testAfternoonContext() {
        let result = parser.parse("Schedule meeting for this afternoon")

        #expect(result.contextHints.contains("afternoon"))
    }

    @Test("Extracts 'after work' as evening")
    func testAfterWorkContext() {
        let result = parser.parse("Hit the gym after work")

        #expect(result.contextHints.contains("evening"))
    }

    // MARK: - Day Context

    @Test("Extracts weekend context")
    func testWeekendContext() {
        let result = parser.parse("Clean the garage this weekend")

        #expect(result.contextHints.contains("weekend"))
    }

    @Test("Extracts weekday context")
    func testWeekdayContext() {
        let result = parser.parse("Call during the week")

        #expect(result.contextHints.contains("weekday"))
    }

    @Test("Extracts specific day context")
    func testSpecificDayContext() {
        let result = parser.parse("Meeting on Monday")

        #expect(result.contextHints.contains("monday"))
    }

    // MARK: - Time Hints

    @Test("Extracts 'tomorrow' time hint")
    func testTomorrowTimeHint() {
        let result = parser.parse("Buy groceries tomorrow")

        #expect(result.timeHint == "tomorrow")
    }

    @Test("Extracts 'next week' time hint")
    func testNextWeekTimeHint() {
        let result = parser.parse("Call mom next week")

        #expect(result.timeHint == "next week")
    }

    @Test("Extracts 'today' time hint")
    func testTodayTimeHint() {
        let result = parser.parse("Finish report today")

        #expect(result.timeHint == "today")
    }

    // MARK: - Tag Extraction

    @Test("Extracts 'call' action tag")
    func testCallActionTag() {
        let result = parser.parse("Call the dentist")

        #expect(result.tags.contains("call"))
    }

    @Test("Extracts shopping tags from 'buy'")
    func testBuyShoppingTag() {
        let result = parser.parse("Buy new shoes")

        #expect(result.tags.contains("shopping"))
    }

    @Test("Extracts family tag from 'mom'")
    func testFamilyTagFromMom() {
        let result = parser.parse("Call mom")

        #expect(result.tags.contains("family"))
    }

    @Test("Extracts family tag from 'dad'")
    func testFamilyTagFromDad() {
        let result = parser.parse("Help dad with yard work")

        #expect(result.tags.contains("family"))
    }

    @Test("Extracts health tag from 'doctor'")
    func testHealthTagFromDoctor() {
        let result = parser.parse("Schedule doctor appointment")

        #expect(result.tags.contains("health"))
    }

    @Test("Extracts work tag from 'boss'")
    func testWorkTagFromBoss() {
        let result = parser.parse("Meeting with boss")

        #expect(result.tags.contains("work"))
    }

    @Test("Extracts multiple tags")
    func testMultipleTags() {
        let result = parser.parse("Call mom to schedule doctor visit")

        #expect(result.tags.contains("call"))
        #expect(result.tags.contains("family"))
        #expect(result.tags.contains("health"))
    }

    // MARK: - Complex Examples

    @Test("Parses complex input with all components")
    func testComplexInput() {
        let result = parser.parse("Remind me to call mom next week when I'm free in the evening")

        #expect(result.title == "Call mom")
        #expect(result.tags.contains("call"))
        #expect(result.tags.contains("family"))
        #expect(result.contextHints.contains("evening"))
        #expect(result.timeHint == "next week")
        #expect(result.priority == .normal)
    }

    @Test("Parses urgent task with time context")
    func testUrgentWithTimeContext() {
        let result = parser.parse("URGENT: Submit expense report by end of day tomorrow")

        #expect(result.priority == .high)
        #expect(result.timeHint == "tomorrow")
        #expect(result.tags.contains("work"))
    }

    @Test("Parses weekend morning task")
    func testWeekendMorningTask() {
        let result = parser.parse("Go to farmer's market Saturday morning")

        #expect(result.contextHints.contains("saturday"))
        #expect(result.contextHints.contains("morning"))
    }

    @Test("Parses low priority future task")
    func testLowPriorityFutureTask() {
        let result = parser.parse("Eventually organize the garage when I have time")

        #expect(result.priority == .low)
        #expect(result.tags.contains("home"))
    }

    // MARK: - Description Generation

    @Test("Generates description with time hint and context")
    func testDescriptionWithTimeAndContext() {
        let result = parser.parse("Call mom next week in the evening")

        #expect(result.description != nil)
        #expect(result.description?.contains("next week") == true || result.description?.contains("evening") == true)
    }

    @Test("Generates description with only time hint")
    func testDescriptionWithOnlyTimeHint() {
        let result = parser.parse("Buy groceries tomorrow")

        #expect(result.description != nil)
        #expect(result.description?.contains("tomorrow") == true)
    }

    @Test("Generates description with only context hints")
    func testDescriptionWithOnlyContextHints() {
        let result = parser.parse("Call mom in the evening")

        #expect(result.description != nil)
        #expect(result.description?.contains("evening") == true)
    }

    // MARK: - Edge Cases

    @Test("Handles empty input")
    func testEmptyInput() {
        let result = parser.parse("")

        #expect(result.title == "")
        #expect(result.tags.isEmpty)
        #expect(result.priority == .normal)
    }

    @Test("Handles input with only whitespace")
    func testWhitespaceInput() {
        let result = parser.parse("   ")

        #expect(result.title.trimmingCharacters(in: .whitespaces) == "")
    }

    @Test("Preserves case in title")
    func testPreservesCase() {
        let result = parser.parse("Email CEO about Q4 results")

        #expect(result.title.contains("CEO"))
        #expect(result.title.contains("Q4"))
    }

    @Test("Handles multiple time references")
    func testMultipleTimeReferences() {
        let result = parser.parse("Plan weekend trip for next month")

        #expect(result.contextHints.contains("weekend"))
        #expect(result.timeHint == "next month")
    }
}
