//
//  StepImplementation.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 8/25/18.
//  Copyright © 2018 Tyler Thompson. All rights reserved.
//

import Foundation

@objc public protocol StepImplementation {
    func setupSteps()
    var bundle: Bundle { get }
    @available(*, unavailable, renamed: "shouldRunWith(scenario:tags:)")
    @objc optional func shouldRunWith(tags: [Tag]) -> Bool
    @objc optional func shouldRunWith(scenario: Scenario?, tags: [Tag]) -> Bool
    @objc optional var continueTestingAfterFailure: Bool { get }
    @objc optional var reverseOrderForAfterHooks: Bool { get }
}
