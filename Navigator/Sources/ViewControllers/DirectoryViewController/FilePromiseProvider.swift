//
//  FilePromiseProvider.swift
//  Navigator
//
//  Created by Thomas Bonk on 07.10.24.
//  Copyright © 2021 Apple Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import AppKit


class FilePromiseProvider: NSFilePromiseProvider {
    
    struct UserInfoKeys {
        static let rowNumberKey = "rowNumber"
        static let urlKey = "url"
    }
    
    /** Required:
        Return an array of UTI strings of data types the receiver can write to the pasteboard.
        By default, data for the first returned type is put onto the pasteboard immediately, with the remaining types being promised.
        To change the default behavior, implement -writingOptionsForType:pasteboard: and return NSPasteboardWritingPromised
        to lazily provided data for types, return no option to provide the data for that type immediately.
     
        Use the pasteboard argument to provide different types based on the pasteboard name, if desired.
        Do not perform other pasteboard operations in the function implementation.
    */
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.append(.fileURL) // Add the .fileURL drag type (to promise files to other apps).
        
        return types
    }
    
    /** Required:
        Return the appropriate property list object for the provided type.
        This will commonly be the NSData for that data type.  However, if this function returns either a string, or any other property-list type,
        the pasteboard will automatically convert these items to the correct NSData format required for the pasteboard.
    */
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        guard let userInfoDict = userInfo as? [String: Any] else { return nil }
    
        switch type {
        case .fileURL:
            // Incoming type is "public.file-url", return (from our userInfo) the URL.
            if let url = userInfoDict[FilePromiseProvider.UserInfoKeys.urlKey] as? NSURL {
                return url.pasteboardPropertyList(forType: type)
            }
            break
        default:
            break
        }
        
        return super.pasteboardPropertyList(forType: type)
    }
    
    /** Optional:
        Returns options for writing data of a type to a pasteboard.
        Use the pasteboard argument to provide different options based on the pasteboard name, if desired.
        Do not perform other pasteboard operations in the function implementation.
     */
    public override func writingOptions(forType type: NSPasteboard.PasteboardType,
                                        pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        
        return super.writingOptions(forType: type, pasteboard: pasteboard)
    }

}
