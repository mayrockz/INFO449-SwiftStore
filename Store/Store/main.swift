//
//  main.swift
//  Store
//
//  Created by Ted Neward on 2/29/24.
//



import Foundation

protocol SKU
{
    var name: String { get }
    func price() -> Int
}



class Item: SKU
{
    let name: String
    private let priceEach: Int

    init(name: String, priceEach: Int)
    {
        self.name = name
        self.priceEach = priceEach
    }

    func price() -> Int
    {
        priceEach
    }
}



class Receipt
{
    private var scannedItems: [SKU] = []

    func add(_ sku: SKU)
    {
        scannedItems.append(sku)
    }

    func items() -> [SKU]
    {
        scannedItems
    }

    func total() -> Int
    {
        scannedItems.reduce(0) { $0 + $1.price() }
    }

    func output() -> String
    {
        var result = "Receipt:\n"
        
        for item in scannedItems
        {
            let dollars = Double(item.price()) / 100.0
            result += "\(item.name): $\(String(format: "%.2f", dollars))\n"
        }
        
        let totalDollars = Double(total()) / 100.0
        result += """
------------------
TOTAL: $\(String(format: "%.2f", totalDollars))
"""
        return result
    }

    func clear()
    {
        scannedItems.removeAll()
    }
}



class Register
{
    private var receipt: Receipt
    private var pricingSchemes: [PricingScheme] = []

    init(pricingSchemes: [PricingScheme] = [])
    {
        self.receipt = Receipt()
        self.pricingSchemes = pricingSchemes
    }

    func scan(_ sku: SKU)
    {
        receipt.add(sku)
    }

    func subtotal() -> Int
    {
        var total = receipt.total()
        
        for scheme in pricingSchemes
        {
            total = scheme.apply(to: receipt)
        }
        
        return total
    }

    func total() -> Receipt
    {
        let finished = receipt
        
        receipt = Receipt()
        
        return finished
    }

    func addPricingScheme(_ scheme: PricingScheme)
    {
        pricingSchemes.append(scheme)
    }
}



class Store
{
    let version = "0.1"

    func helloWorld() -> String
    {
        "Hello world"
    }
}



protocol PricingScheme
{
    func apply(to receipt: Receipt) -> Int
}



class BunchedPricing: PricingScheme
{
    private let itemName: String
    private let buy: Int
    private let pay: Int

    init(itemName: String, buy: Int, pay: Int)
    {
        self.itemName = itemName
        self.buy = buy
        self.pay = pay
    }

    func apply(to receipt: Receipt) -> Int
    {
        let items = receipt.items().filter { $0.name == itemName }
        guard !items.isEmpty else { return receipt.total() }

        let itemPrice = items.first!.price()
        let totalItems = items.count

        let fullGroups = totalItems / buy
        let remainder = totalItems % buy

        let discountedTotal = (fullGroups * pay + remainder) * itemPrice
        let otherTotal = receipt.items().filter { $0.name != itemName }.reduce(0) { $0 + $1.price() }

        return discountedTotal + otherTotal
    }
}


class GroupedDiscount: PricingScheme
{
    private let groupNames: Set<String>
    private let discountPercent: Double

    init(groupNames: [String], discountPercent: Double)
    {
        self.groupNames = Set(groupNames)
        self.discountPercent = discountPercent
    }

    func apply(to receipt: Receipt) -> Int
    {
        let total = receipt.total()
        let items = receipt.items()
        let itemsInGroup = items.filter { groupNames.contains($0.name) }

        guard itemsInGroup.count == groupNames.count else
        {
            return total
        }

        let discount = itemsInGroup.reduce(0) { $0 + Int(Double($1.price()) * discountPercent / 100.0) }
        
        return total - discount
    }
}



class WeightedItem: SKU
{
    let name: String
    private let pricePerPound: Int
    private let weight: Double

    init(name: String, pricePerPound: Int, weight: Double)
    {
        self.name = name
        self.pricePerPound = pricePerPound
        self.weight = weight
    }

    func price() -> Int
    {
        return Int(round(Double(pricePerPound) * weight))
    }
}



class Coupon: PricingScheme
{
    private let itemName: String
    private let discountPercent: Double
    private var used = false

    init(itemName: String, discountPercent: Double = 15)
    {
        self.itemName = itemName
        self.discountPercent = discountPercent
    }

    func apply(to receipt: Receipt) -> Int
    {
        if used { return receipt.total() }

        var total = 0
        var applied = false
        
        for item in receipt.items()
        {
            if item.name == itemName && !applied
            {
                let discountedPrice = Int(Double(item.price()) * (1.0 - discountPercent / 100))
                
                total += discountedPrice
                applied = true
            }
            else
            {
                total += item.price()
            }
        }
        
        used = applied
        
        return total
    }
}


class RainCheck: PricingScheme
{
    private let itemName: String
    private let specialPrice: Int
    private var applied = false

    init(itemName: String, specialPrice: Int)
    {
        self.itemName = itemName
        self.specialPrice = specialPrice
    }

    func apply(to receipt: Receipt) -> Int
    {
        var total = 0
        var appliedThisTime = false

        for item in receipt.items()
        {
            if item.name == itemName && !applied && !appliedThisTime
            {
                total += specialPrice
                appliedThisTime = true
            }
            else
            {
                total += item.price()
            }
        }

        if appliedThisTime { applied = true }
        
        return total
    }
}
