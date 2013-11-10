//
//  OTPAuthURLTest.m
//
//  Copyright 2013 Matt Rubin
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

@import XCTest;

#define STAssertEqualObjects XCTAssertEqualObjects
#define STAssertEquals XCTAssertEqual
#define STAssertTrue XCTAssertTrue
#define STAssertFalse XCTAssertFalse
#define STAssertNil XCTAssertNil

#import "OTPToken+Serialization.h"
#import "OTPToken+Persistence.h"
#import "NSDictionary+QueryString.h"

static NSString *const kOTPAuthScheme = @"otpauth";

// These are keys in the otpauth:// query string.
static NSString *const kQueryAlgorithmKey = @"algorithm";
static NSString *const kQuerySecretKey = @"secret";
static NSString *const kQueryCounterKey = @"counter";
static NSString *const kQueryDigitsKey = @"digits";
static NSString *const kQueryPeriodKey = @"period";

static NSString *const kValidType = @"totp";
static NSString *const kValidLabel = @"Léon";
static NSString *const kValidAlgorithm = @"SHA256";
static const unsigned char kValidSecret[] =
    { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
      0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };
static NSString *const  kValidBase32Secret = @"AAAQEAYEAUDAOCAJBIFQYDIOB4";
static const unsigned long long kValidCounter = 18446744073709551615ULL;
static NSString *const kValidCounterString = @"18446744073709551615";
static const NSUInteger kValidDigits = 8;
static NSString *const kValidDigitsString = @"8";
static const NSTimeInterval kValidPeriod = 45;
static NSString *const kValidPeriodString = @"45";

static NSString *const kValidTOTPURLWithoutSecret =
    @"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45";

static NSString *const kValidTOTPURL =
    @"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45"
    @"&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4";

static NSString *const kValidHOTPURL =
    @"otpauth://hotp/L%C3%A9on?algorithm=SHA256&digits=8"
    @"&counter=18446744073709551615"
    @"&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4";

@interface OTPToken ()

+ (instancetype)tokenWithKeychainDictionary:(NSDictionary *)keychainDictionary;
@property (nonatomic, readonly) BOOL isInKeychain;

@end

@interface OTPAuthURLTest : XCTestCase
- (void)testInitWithKeychainDictionary;
- (void)testInitWithTOTPURL;
- (void)testInitWithHOTPURL;
- (void)testInitWithInvalidURLS;
- (void)testInitWithOTPGeneratorLabel;
- (void)testURL;

@end

@implementation OTPAuthURLTest

- (void)testInitWithKeychainDictionary {
  NSData *secret = [NSData dataWithBytes:kValidSecret
                                  length:sizeof(kValidSecret)];
  NSData *urlData = [kValidTOTPURLWithoutSecret
                     dataUsingEncoding:NSUTF8StringEncoding];

  OTPToken *token = [OTPToken tokenWithKeychainDictionary:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      urlData, (id)kSecAttrGeneric,
                      secret, (id)kSecValueData,
                      nil]];

  STAssertEqualObjects([token name], kValidLabel, @"Léon");

  STAssertEqualObjects([token secret], secret, @"");
  STAssertEqualObjects([NSString stringForAlgorithm:token.algorithm], kValidAlgorithm, @"");
  STAssertEquals([token period], kValidPeriod, @"");
  STAssertEquals([token digits], kValidDigits, @"");

  STAssertFalse([token isInKeychain], @"");
}

- (void)testInitWithTOTPURL {
  NSData *secret = [NSData dataWithBytes:kValidSecret
                                  length:sizeof(kValidSecret)];

  OTPToken *token
    = [OTPToken tokenWithURL:[NSURL URLWithString:kValidTOTPURL]];

  STAssertEqualObjects(token.name, kValidLabel, @"Léon");

  STAssertEqualObjects([token secret], secret, @"");
  STAssertEqualObjects([NSString stringForAlgorithm:token.algorithm], kValidAlgorithm, @"");
  STAssertEquals([token period], kValidPeriod, @"");
  STAssertEquals([token digits], kValidDigits, @"");
}

- (void)testInitWithHOTPURL {
  NSData *secret = [NSData dataWithBytes:kValidSecret
                                  length:sizeof(kValidSecret)];

  OTPToken *token
    = [OTPToken tokenWithURL:[NSURL URLWithString:kValidHOTPURL]];

  STAssertEqualObjects([token name], kValidLabel, @"Léon");

  STAssertEqualObjects([token secret], secret, @"");
  STAssertEqualObjects([NSString stringForAlgorithm:token.algorithm], kValidAlgorithm, @"");
  STAssertEquals([token counter], kValidCounter, @"");
  STAssertEquals([token digits], kValidDigits, @"");
}

- (void)testInitWithInvalidURLS {
  NSArray *badUrls = [NSArray arrayWithObjects:
      // invalid scheme
      @"http://foo",
      // invalid type
      @"otpauth://foo",
      // missing secret
      @"otpauth://totp/bar",
      // invalid period
      @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&period=0",
      // invalid algorithm
      @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&algorithm=RC4",
      // invalid digits
      @"otpauth://totp/bar?secret=AAAQEAYEAUDAOCAJBIFQYDIOB4&digits=2",
      nil];

  for (NSString *badUrl in badUrls) {
    OTPToken *token
      = [OTPToken tokenWithURL:[NSURL URLWithString:badUrl]];
    STAssertNil(token, @"invalid url (%@) generated %@", badUrl, token);
  }
}

- (void)testInitWithOTPGeneratorLabel {
    OTPToken *token = [[OTPToken alloc] init];
    token.name = kValidLabel;
    token.type = OTPTokenTypeTimer;
    token.secret = [NSData data];

  STAssertEqualObjects([token name], kValidLabel, @"");
  STAssertFalse([token isInKeychain], @"");
}

- (void)testURL {
  OTPToken *token
    = [OTPToken tokenWithURL:[NSURL URLWithString:kValidTOTPURL]];

  STAssertEqualObjects([[token url] scheme], kOTPAuthScheme, @"");
  STAssertEqualObjects([[token url] host], kValidType, @"");
  STAssertEqualObjects([[[token url] path] substringFromIndex:1],
                       kValidLabel,
                       @"");
  NSDictionary *result =
      [NSDictionary dictionaryWithObjectsAndKeys:
       kValidAlgorithm, kQueryAlgorithmKey,
       kValidDigitsString, kQueryDigitsKey,
       kValidPeriodString, kQueryPeriodKey,
       nil];
  STAssertEqualObjects([NSDictionary dictionaryWithQueryString:
                        [[token url] query]],
                       result,
                       @"");

  OTPToken *token2
    = [OTPToken tokenWithURL:[NSURL URLWithString:kValidHOTPURL]];

  NSDictionary *resultForHOTP =
      [NSDictionary dictionaryWithObjectsAndKeys:
       kValidAlgorithm, kQueryAlgorithmKey,
       kValidDigitsString, kQueryDigitsKey,
       kValidCounterString, kQueryCounterKey,
       nil];
  STAssertEqualObjects([NSDictionary dictionaryWithQueryString:
                        [[token2 url] query]],
                       resultForHOTP,
                       @"");
}

- (void)testDuplicateURLs {
  NSURL *url = [NSURL URLWithString:kValidTOTPURL];
  OTPToken *token1 = [OTPToken tokenWithURL:url];
  OTPToken *token2 = [OTPToken tokenWithURL:url];
  STAssertTrue([token1 saveToKeychain], @"");
  STAssertTrue([token2 saveToKeychain], @"");
  STAssertTrue([token1 removeFromKeychain],
               @"Your keychain may now have an invalid entry %@", token1);
  STAssertTrue([token2 removeFromKeychain],
               @"Your keychain may now have an invalid entry %@", token2);
}

@end