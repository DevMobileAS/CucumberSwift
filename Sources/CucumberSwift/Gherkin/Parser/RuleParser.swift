//
//  RuleParser.swift
//  CucumberSwift
//
//  Created by Tyler Thompson on 12/7/19.
//  Copyright © 2019 Tyler Thompson. All rights reserved.
//

import Foundation
enum RuleParser {
    static func parse(_ ruleNode: AST.RuleNode, featureTags: [Tag], backgroundStepNodes: [AST.StepNode]) -> [Scenario] {
        let backgroundSteps: [AST.StepNode] = backgroundStepNodes.appending(contentsOf:
            ruleNode.children
            .compactMap { $0 as? AST.BackgroundNode }
            .flatMap { $0.children.compactMap { $0 as? AST.StepNode } })
        return ruleNode
            .children
            .compactMap { $0 as? AST.ScenarioNode }
            .map { Scenario(with: $0, tags: featureTags, stepNodes: backgroundSteps) }
    }
}
