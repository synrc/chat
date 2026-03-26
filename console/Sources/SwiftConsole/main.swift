import Crypto
import Foundation

try Console.loop()

public class Console {

  public static var quit = false
  public static var no = 2

  public static func loop() throws {
     print(": CHAT 💬 X.509 © SYNRC")
     while (!quit) {
         Cmd.nop() ; let data = parse(readLine()!)
         switch (data) { case []: continue ; default: quit = try Cmd.execute(data) }
     }
     print(": Bye!")
  }

  public static func parse(_ line: String) -> Array<String> {
     let data = line.components(separatedBy: " ")
     if (data.joined() == "") {
         return []
     } else {
         let args  = data.filter { $0 != "" }
         return args
     }
  }

}

