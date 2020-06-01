//
//  BackupService.swift
//  Authenticator
//
//  Copyright (c) 2015-2019 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import OneTimePassword
import Security
import CommonCrypto
import CryptoSwift
import Base32

// TODO: document
protocol BackupService {
    func `import`(backup: Data, password: String) throws -> [Token]
    func export(tokens: [Token], password: String) throws -> Data
}

class BackupServiceImpl: BackupService {
    func `import`(backup: Data, password: String) throws -> [Token] {
        // Decryption: Extract parameters from backup data.
        let iterationsBytes = backup.subdata(in: 0..<4)
        var iterationsBigEndian: Int32 = 0
        _ = withUnsafeMutableBytes(of: &iterationsBigEndian) { iterationsBytes.copyBytes(to: $0) }
        let iterations = Int32(bigEndian: iterationsBigEndian)

        let salt = backup.subdata(in: 4..<16)
        let iv = backup.subdata(in: 16..<28)
        let payload = backup.subdata(in: 28..<backup.count)

        // Decryption: Derive AES key from `password`.
        let key = try PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: Int(iterations), keyLength: 32, variant: .sha1).calculate()

        // Decryption: Perform AES decryption.
        let aes = try AES(key: key, blockMode: GCM(iv: iv.bytes, mode: .combined), padding: .noPadding)
        let plaintext = try aes.decrypt(payload.bytes)

        // TODO: Report parse failures to the user instead of silently ignoring.
        return (String(data: Data(plaintext), encoding: .utf8)?
            .split(separator: "\n") ?? [])
            .compactMap { uri in URL(string: String(uri)).flatMap { Token(url: $0) } }
    }

    func export(tokens: [Token], password: String) throws -> Data {
        // Create plaintext message
        // https://github.com/Authenticator-Extension/Authenticator/wiki/Standard-OTP-Backup-Format
        let plaintext = try tokens
            .map { token in
                var uri = try token.toURI()
                let secret = MF_Base32Codec.base32String(from: token.generator.secret)
                let secretQueryItem = URLQueryItem(name: "secret", value: secret)
                if uri.queryItems != nil {
                    uri.queryItems!.append(secretQueryItem)
                } else {
                    uri.queryItems = [secretQueryItem]
                }
                return uri.string!
            }
            .joined(separator: "\n")

        // Encryption: Derive an AES key from `password` using PBKDF2.
        // TODO: 140000...160000
        let iterations = Int32.random(in: 1400...1600)
        let salt = (0..<12).map { _ in UInt8.random(in: 0...UInt8.max) }
        let key = try PKCS5.PBKDF2(password: password.bytes, salt: salt, iterations: Int(iterations), keyLength: 32, variant: .sha1).calculate()

        // Encryption: Perform AES GCM NoPadding encryption.
        let iv = AES.randomIV(12)
        let gcm = GCM(iv: iv, mode: .combined)
        let aes = try AES(key: key, blockMode: gcm, padding: .noPadding)
        let encrypted = try aes.encrypt(plaintext.bytes)

        // Encryption: Concatenate iterations, salt, iv, and payload.
        let iterationBytes = withUnsafeBytes(of: iterations.bigEndian, Data.init)
        let backupData = iterationBytes + salt + iv + Data(encrypted)

        return backupData
    }
}
