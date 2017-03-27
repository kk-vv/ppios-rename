#import <Kiwi/Kiwi.h>
#import "CDSystemProtocolsProcessor.h"

SPEC_BEGIN(CDSystemProtocolsProcessorSpec)
    describe(@"CDSystemProtocolsProcessor", ^{
        __block CDSystemProtocolsProcessor* parser;

        beforeEach(^{
            // This is an integration test disguised as a unit test -- not everyone has Xcode at the default location.
            NSPipe *pipe = [NSPipe pipe];
            NSFileHandle *handle = pipe.fileHandleForReading;
            
            NSTask *task = [NSTask new];
            task.launchPath = @"/usr/bin/xcode-select";
            task.arguments = @[@"-p"];
            task.standardOutput = pipe;
            
            [task launch];
            
            NSData *xcodePathData = [handle readDataToEndOfFile];
            [handle closeFile];
            
            NSString *xcodePathRaw = [[NSString alloc] initWithData:xcodePathData encoding:NSUTF8StringEncoding];
            NSString *xcodePath = [xcodePathRaw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *sdkRoots = @[[xcodePath stringByAppendingString:@"/Platforms/iPhoneOS.platform/Developer/SDKs/"],
                                  @"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/"];

            for (NSString *sdkRoot in sdkRoots) {
                NSArray* sdkPaths = [[NSFileManager defaultManager]
                             contentsOfDirectoryAtPath:sdkRoot
                             error:NULL];
            
                for (NSString *sdkPath in sdkPaths) {
                    if ([sdkPath hasPrefix:@"iPhoneOS"]) {
                        parser = [[CDSystemProtocolsProcessor alloc] initWithSdkPath:[sdkRoot stringByAppendingString:sdkPath]];
                        return;
                    }
                }
            }
        });

        describe(@"retrieving protocol symbols to exclude", ^{
            __block NSArray *symbols;
            beforeAll(^{
                symbols = [parser systemProtocolsSymbolsToExclude];
            });

            it(@"should contain UIWebViewDelegate, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate", ^{
                [[symbols should] contain:@"UIWebViewDelegate"];
                [[symbols should] contain:@"UIPickerViewDelegate"];
                [[symbols should] contain:@"UITableViewDelegate"];
                [[symbols should] contain:@"UITableViewDataSource"];
                [[symbols should] contain:@"UINavigationControllerDelegate"];
            });
        });
    });
SPEC_END
