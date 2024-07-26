//
//  Taggable.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 5/13/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation
public protocol Taggable {
    var tags: [Tag] { get }
    func containsTags(_ tags: [Tag]) -> Bool
}
extension Taggable {
    func containsTag(_ tag: Tag) -> Bool {
        tags.contains(tag)
    }
}

@objc public class Tag: NSObject, Encodable {
    var rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // features/scenarios with this tag will only run for testing on real (iPhone, iPad) device
    public static let deviceOnly = Tag("device")

    // features/scenarios with this tag will only run for testing on simulator
    public static let simOnly = Tag("simulator")

    // can be used in combination with `Cucumber.enableCucumberSelection` to explictitly enable specific // features/scenarios and ignore the rest
    public static let selected = Tag("selected")

    // you can even disable tests by tag
    public static let skipped = Tag("skipped")

    // you can even disable tests by tag
    public static let disabled = Tag("disabled")
}

extension [Tag] {
    init(_ tags: [String]) {
        self = tags.map { Tag($0) }
    }

    func contains(_ tag: Tag) -> Bool {
        contains { $0.rawValue == tag.rawValue }
    }
}

extension Array where Element: Taggable {
    func taggedElements(with environment: [String: String] = ProcessInfo.processInfo.environment, askImplementor: Bool) -> [Element] {
        if let tagNames = environment["CUCUMBER_TAGS"] {
            let tags = [Tag](tagNames.components(separatedBy: ","))
            return filter { $0.containsTags(tags) }
        } else if let shouldRunWith = (Cucumber.shared as? StepImplementation)?.shouldRunWith,
            askImplementor {
            return filter {
                let scenario = $0 as? Scenario
                let tags = $0.tags
                return checkDefaultTags(scenario: scenario, tags: tags) && shouldRunWith(scenario, tags)
            }
        }
        return self
    }

    public func checkDefaultTags(scenario: Scenario?, tags: [Tag]) -> Bool {

        if tags.contains(Tag.disabled) {
            return false
        }

        if Cucumber.shared.cucumberSelectionIsEnabled && !tags.contains(Tag.selected) {
            return false
        }

#if targetEnvironment(simulator)
        // in the .feature files the tag @deviceOnly is used to skip tests for simulator
        return !tags.contains(Tag.deviceOnly)
#else
        return !tags.contains(Tag.simOnly)
#endif
    }
}
