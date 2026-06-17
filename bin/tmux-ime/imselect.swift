// 入力ソースを切り替える小さなCLI。
// TISSelectInputSource を使うだけなので特別な権限は不要。単発実行。
//
// 使い方:
//   imselect abc      ABC(英字)に切替
//   imselect ja       日本語(ことえり かな)に切替
//   imselect <id>     任意の input source ID に切替
//   imselect list     選択可能な input source ID を一覧表示
//   imselect current  現在の input source ID を表示

import Cocoa
import Carbon

let abcID = "com.apple.keylayout.ABC"
let jaID = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"

func allSources() -> [TISInputSource] {
    guard let cf = TISCreateInputSourceList(nil, false)?.takeRetainedValue(),
          let list = cf as? [TISInputSource] else { return [] }
    return list
}

func sourceID(_ s: TISInputSource) -> String? {
    guard let ptr = TISGetInputSourceProperty(s, kTISPropertyInputSourceID) else { return nil }
    return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
}

func selectByID(_ id: String) -> Bool {
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    guard let cf = TISCreateInputSourceList(filter, false)?.takeRetainedValue(),
          let list = cf as? [TISInputSource], let src = list.first else { return false }
    return TISSelectInputSource(src) == noErr
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("usage: imselect <abc|ja|list|current|input-source-id>")
    exit(1)
}

switch args[1] {
case "list":
    for s in allSources() {
        if let id = sourceID(s) { print(id) }
    }
case "current":
    if let s = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
       let id = sourceID(s) { print(id) }
case "abc":
    exit(selectByID(abcID) ? 0 : 1)
case "ja":
    exit(selectByID(jaID) ? 0 : 1)
default:
    exit(selectByID(args[1]) ? 0 : 1)
}
