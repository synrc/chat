import Foundation
import Crypto

extension String {
  func leftPad(toLength: Int, withPad character: Character) -> String {
       if count < toLength { return String(repeating: character, count: toLength - count) + self }
       else { return self } } }

public class Form {

  public struct screen {
    let no: Int
    let name: String
    let sections: [section]
  }

  public struct section {
    let name: String
    let rows: [row]
  }

  public struct row {
    let no: Int
    let desc: String
    let rico: (String,String)
  }

  public static func show(data: Array<String>) throws {
   let app = App.screens
    if (data.count < 2) {
      print(": Not enough arguments: form <NO | list>")
    } else if (data[1] == "list") {
      for i in 0...app.count-1 {
        let no = String(app[i].no).leftPad(toLength: 3, withPad: "0")
        print("\u{1b}[0m\u{1b}[1;97m\u{1b}[45m \(no) ", terminator: "")
        print("\u{1b}[0;93m\u{1b}[0;104m \(app[i].name) ", terminator: "")
        print("\u{1b}[0m\u{1b}[0K")
      }
    } else {
      for i in 0...app.count-1 {
        if (app[i].no == Int(data[1])) {
          let screen = app[i].name
          let name = app[i].sections[0].name
          print("     \u{1b}[0;97m\u{1b}[1;104m \(screen) \u{1b}[0m\u{1b}[0K")
          print("\u{1b}[1;33m\u{1b}[44m▄▄▄▄▄\u{1b}[0;97m\u{1b}[1;104m \(name) \u{1b}[0m\u{1b}[0K")
          if (app[i].sections[0].rows.count == 0) { continue }
          for j in 0...app[i].sections[0].rows.count-1 {
            let no = String(app[i].sections[0].rows[j].no).leftPad(toLength: 3, withPad: "0")
            let desc = String(app[i].sections[0].rows[j].desc).padding(toLength: 30, withPad: " ", startingAt:0)
            print("\u{1b}[0m\u{1b}[1;97m\u{1b}[45m \(no) ", terminator: "")
            print("\u{1b}[0;93m\u{1b}[0;104m \(desc)", terminator: "")
            print("\u{1b}[0m\u{1b}[0K")
          }
        }
      }
    }
  }

}