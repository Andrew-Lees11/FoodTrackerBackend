//
//  FoodTrackerTests.swift
//  FoodTrackerTests
//
//  Created by Jane Appleseed on 10/17/16.
//  Copyright © 2016 Apple Inc. All rights reserved.
//

import XCTest
@testable import FoodTracker

class FoodTrackerTests: XCTestCase {
    
    //MARK: Meal Class Tests
    
    // Confirm that the Meal initializer returns a Meal object when passed valid parameters.
    func testMealInitializationSucceeds() {
        
        // Zero rating
        let zeroRatingMeal = Meal.init(name: "Zero", photo: Data(), rating: 0)
        XCTAssertNotNil(zeroRatingMeal)

        // Positive rating
        let positiveRatingMeal = Meal.init(name: "Positive", photo: Data(), rating: 5)
        XCTAssertNotNil(positiveRatingMeal)

    }
    
    // Confirm that the Meal initialier returns nil when passed a negative rating or an empty name.
    func testMealInitializationFails() {
        
        // Negative rating
        let negativeRatingMeal = Meal.init(name: "Negative", photo: Data(), rating: -1)
        XCTAssertNil(negativeRatingMeal)
        
        // Rating exceeds maximum
        let largeRatingMeal = Meal.init(name: "Large", photo: Data(), rating: 6)
        XCTAssertNil(largeRatingMeal)

        // Empty String
        let emptyStringMeal = Meal.init(name: "", photo: Data(), rating: 0)
        XCTAssertNil(emptyStringMeal)
        
    }
}
