// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Dispatch
import Foundation
import Swift

extension DispatchSource {
    static func makeReadTextSource<S: Subject>(
        pipe: Pipe,
        queue: DispatchQueue,
        sink: S,
        encoding: String.Encoding = .utf8
    ) -> DispatchSourceRead where S.Output == String {
        let pipe = Pipe()
        let fileDescriptor = pipe.fileHandleForReading.fileDescriptor
        let readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: queue)
        
        readSource.setEventHandler { [weak readSource = readSource] in
            guard let data = readSource?.data else {
                return
            }
            
            let estimatedBytesAvailableToRead = Int(data)
            
            var buffer = [UInt8](repeating: 0, count: estimatedBytesAvailableToRead)
            let bytesRead = read(fileDescriptor, &buffer, estimatedBytesAvailableToRead)
            
            guard bytesRead > 0, let availableString = String(bytes: buffer, encoding: encoding) else {
                return
            }
            
            sink.send(availableString)
        }
                
        return readSource
    }
}

#endif
