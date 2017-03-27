/********************************************
  Copyright 2016-2017 PreEmptive Solutions, LLC
  See LICENSE.txt for licensing information
********************************************/
  
#import "CDVisitor.h"


@interface CDSymbolsGeneratorVisitor : CDVisitor
@property (nonatomic, copy) NSArray<NSString *> *classFilters;
@property (nonatomic, copy) NSArray<NSString *> *exclusionPatterns;
@property (nonatomic, readonly) NSDictionary *symbols;
@property (nonatomic, copy) NSString *diagnosticFilesPrefix;
@property (nonatomic, copy) NSString *frameworkName;

+ (void)appendDefineTo:(NSMutableString *)stringBuilder
              renaming:(NSString *)oldName
                    to:(NSString *)newName;

+ (void)writeSymbols:(NSDictionary<NSString *, NSString *> *)symbols
   symbolsHeaderFile:(NSString *)symbolsHeaderFile;
@end
