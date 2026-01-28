//
//  StoreTests.swift
//  StoreTests
//
//  Created by Ted Neward on 2/29/24.
//

import XCTest

final class StoreTests: XCTestCase
{
    
    var register = Register()
    
    override func setUpWithError() throws {
        register = Register()
    }
    
    override func tearDownWithError() throws { }
    
    func testBaseline() throws {
        XCTAssertEqual("0.1", Store().version)
        XCTAssertEqual("Hello world", Store().helloWorld())
    }
    
    func testOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(199, receipt.total())
        
        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
------------------
TOTAL: $1.99
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testThreeSameItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 3, register.subtotal())
    }
    
    func testThreeDifferentItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        register.scan(Item(name: "Pencil", priceEach: 99))
        XCTAssertEqual(298, register.subtotal())
        register.scan(Item(name: "Granols Bars (Box, 8ct)", priceEach: 499))
        XCTAssertEqual(797, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(797, receipt.total())
        
        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
Pencil: $0.99
Granols Bars (Box, 8ct): $4.99
------------------
TOTAL: $7.97
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    
    
    func testAddingSingleItemToRegister()
    {
        let register = Register()
        let item = Item(name: "Beans (8oz Can)", priceEach: 199)
        
        register.scan(item)
        
        let subtotal = register.subtotal()
        
        XCTAssertEqual(199, subtotal, "Subtotal should equal the price of the single item scanned")
    }
    
    func testMultipleItemsSubtotal()
    {
        let register = Register()
        register.scan(Item(name: "Beans", priceEach: 199))
        register.scan(Item(name: "Pencil", priceEach: 99))
        
        XCTAssertEqual(298, register.subtotal())
    }
    
    func testRegisterClearsAfterTotal()
    {
        let register = Register()
        register.scan(Item(name: "Beans", priceEach: 199))
        
        _ = register.total()
        
        XCTAssertEqual(0, register.subtotal())
    }
    
    func testBunchedPricing()
    {
        let bunched = BunchedPricing(itemName: "Beans", buy: 3, pay: 2)
        let register = Register(pricingSchemes: [bunched])
        
        register.scan(Item(name: "Beans", priceEach: 199))
        register.scan(Item(name: "Beans", priceEach: 199))
        register.scan(Item(name: "Beans", priceEach: 199))
        
        XCTAssertEqual(register.subtotal(), 199 * 2, "3-for-2 pricing should charge for 2 items")
    }
    
    func testGroupedDiscount()
    {
        let grouped = GroupedDiscount(groupNames: ["Ketchup", "Beer"], discountPercent: 10)
        let register = Register(pricingSchemes: [grouped])
        
        register.scan(Item(name: "Ketchup", priceEach: 500))
        register.scan(Item(name: "Beer", priceEach: 1200))
        
        let expected = 500 - 50 + 1200 - 120
        XCTAssertEqual(register.subtotal(), expected)
        
        let register2 = Register(pricingSchemes: [grouped])
        register2.scan(Item(name: "Ketchup", priceEach: 500))
        XCTAssertEqual(register2.subtotal(), 500)
    }
    
    func testWeightedItem()
    {
        let weighted = WeightedItem(name: "Apples", pricePerPound: 199, weight: 1.5)
        XCTAssertEqual(weighted.price(), 299)
    }
    
    func testCoupon()
    {
        let coupon = Coupon(itemName: "Beans", discountPercent: 15)
        let register = Register(pricingSchemes: [coupon])
        
        register.scan(Item(name: "Beans", priceEach: 200))
        register.scan(Item(name: "Beans", priceEach: 200))
        
        XCTAssertEqual(register.subtotal(), 370)
    }
    
    func testRainCheck()
    {
        let rainCheck = RainCheck(itemName: "Beans", specialPrice: 150)
        let register = Register(pricingSchemes: [rainCheck])
        
        register.scan(Item(name: "Beans", priceEach: 200))
        register.scan(Item(name: "Beans", priceEach: 200))
        
        XCTAssertEqual(register.subtotal(), 350)
        
        let rc2 = RainCheck(itemName: "Milk", specialPrice: 100)
        let register2 = Register(pricingSchemes: [rc2])
        register2.scan(Item(name: "Beans", priceEach: 200))
        XCTAssertEqual(register2.subtotal(), 200)
    }
}
