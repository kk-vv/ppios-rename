/********************************************
  Copyright 2016 PreEmptive Solutions, LLC
  See LICENSE.txt for licensing information
********************************************/
  
#import <Kiwi/Kiwi.h>

#import "CDCoreDataModelParser.h"

SPEC_BEGIN(CDCoreDataModelParserSpec)

    describe(@"CDCoreDataModelParser", ^{
        __block CDCoreDataModelParser *parser;


        __block NSURL *fileUrl;
        NSString *className = @"TestEntityA";
        NSString *parentClass = @"TestParentEntity";

        beforeEach(^{
            parser = [[CDCoreDataModelParser alloc] init];
            for (NSBundle *bundle in [NSBundle allBundles]) {
                NSURL *url = [bundle URLForResource:@"contents" withExtension:nil];
                if (url) {
                    fileUrl = url;
                }
            }
        });

        describe(@"parsing core data model", ^{
            it(@"should generate symbol for class name", ^{
                NSArray *symbols = [parser symbolsInData:[NSData dataWithContentsOfURL:fileUrl]];

                [[symbols should] contain:[NSString stringWithFormat:@"!%@", className]];
            });

            it(@"should generate symbol for parent class name", ^{
                NSArray *symbols = [parser symbolsInData:[NSData dataWithContentsOfURL:fileUrl]];

                [[symbols should] contain:[NSString stringWithFormat:@"!%@", parentClass]];
            });
        });
    });

SPEC_END
