//
//  ImportCommands.swift
//  App
//
//  Created by Hadi Sharghi on 12/25/19.
//


import Foundation
import Command


struct ImportCommand: Command {

    var arguments: [CommandArgument] {
        return []
    }
    
    var options: [CommandOption] {
        return [
            .value(name: "category", short: "c", default: "yes", help: ["Import categories"]),
            .value(name: "brand", short: "b", default: "yes", help: ["Import brands"]),
            .value(name: "product", short: "p", default: "yes", help: ["Import products"]),
            .value(name: "image", short: "i", default: "yes", help: ["Assign images to products while importing products."]),
            .value(name: "similar", short: "s", default: "yes", help: ["Add random similar products to each product\nNeeds to import products first."]),
        ]
    }

    var help: [String] {
        return ["Importer for Sylius shop"]
    }
    
    func run(using context: CommandContext) throws -> Future<Void> {
//        let crawlType1 = try context.argument("category")
//        let crawlType2 = try context.argument("product")
        

        /// We can use requireOption here since both options have default values
        let categoryOption = context.options["category"] ?? "no"
        let brandOption = context.options["brand"] ?? "no"
        let productOption = context.options["product"] ?? "no"
        let imageOption = context.options["image"] ?? "no"
        let similarOption = context.options["similar"] ?? "no"

        
        if categoryOption == "yes" {
            let categoryImporter = try CategoryImporter(container: context.container)
            DispatchQueue.global().async {
                let result = categoryImporter.start()
                context.console.print(result ?? "", newLine: true)
            }
        }

        if brandOption == "yes" {
            let brandImporter = try BrandImporter(container: context.container)
            DispatchQueue.global().async {
                context.console.print(brandImporter.start() ?? "", newLine: true)
            }
        }

        if brandOption == "yes" || categoryOption == "yes" {
            return .done(on: context.container)
        }
        
        
        if productOption == "yes" {
            
        }

        
        if productOption == "yes" {
//            let crawler = CrawlerCore(app: context.container)
//            crawler.getProducts()
        }
        

//        let categoryOption = try context.requireOption("category")
//        let productOption = try context.requireOption("product")
//        let persistOption = try context.requireOption("persist")
//        let imageOption = try context.requireOption("image")
        
        context.console.print(context.options.description, newLine: true)
        context.console.print(categoryOption, newLine: true)
        context.console.print(productOption, newLine: true)
        return .done(on: context.container)
    }



}

struct BatteryCommand: Command {

    var arguments: [CommandArgument] {
        return []
    }

    var options: [CommandOption] {
        return []
    }
    var help: [String] {
      return ["Usage:", "Estatus batt"]
    }

    func run(using context: CommandContext) throws -> Future<Void> {
      let pmset = Process()
      let pipe = Pipe()
      if #available(OSX 13, *) {
        pmset.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      } else {
        pmset.launchPath = "/usr/bin/env"
      }
      pmset.arguments = ["pmset", "-g", "batt"]
      pmset.standardOutput = pipe
      do {
      if #available(OSX 13, *) {
        try pmset.run()
      } else {
        pmset.launch()
      }
        pmset.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: String.Encoding.utf8) {
          context.console.print(output)
        }
      }
      return .done(on: context.container)
    }
}
