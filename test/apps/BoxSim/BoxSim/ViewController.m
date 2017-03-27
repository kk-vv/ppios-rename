//
//  ViewController.m
//  BoxSim
//
//  Copyright 2016 PreEmptive Solutions, LLC
//  See LICENSE.txt for licensing information
//

#import "ViewController.h"
#import "TextDisplay.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (void)write:(NSString *)text;
@end

@implementation TextDisplay
- (void)write:(NSString *)text {
}
@end

@interface ViewTextDisplay : TextDisplay {
    ViewController * controller;
}
- (void)set:(ViewController *)newValue;
@end

@implementation ViewTextDisplay
- (void)set:(ViewController *)newValue {
    controller = newValue;
}

- (void)write:(NSString *)text {
    [controller write:text];
}
@end

@interface BSClassP : NSObject
- (void)doSomethingP:(TextDisplay *)textDisplay;
@end

static int countTilCrash = 3;
@implementation BSClassP
- (void)doSomethingP:(TextDisplay *)textDisplay {
    [textDisplay write:@"enter:doSomethingP\n"];
    if (--countTilCrash <= 0) {
        char * x = 0x0;
        *x = 6;
    }
    [textDisplay write:[NSString stringWithFormat:@"count:%d\n", countTilCrash]];
    [textDisplay write:@"exit:doSomethingP\n"];
}
@end

@interface BSClassO : NSObject
- (void)doSomethingO:(TextDisplay *)textDisplay;
@end

@implementation BSClassO : NSObject
- (void)doSomethingO:(TextDisplay *)textDisplay {
    [textDisplay write:@"enter:doSomethingO\n"];
    BSClassP * classP = [BSClassP new];
    [classP doSomethingP:textDisplay];
    [textDisplay write:@"exit:doSomethingO\n"];
}
@end

@interface BSClassN : NSObject
+ (void)doSomethingInClassN:(TextDisplay *)textDisplay;
@end

@implementation BSClassN
+ (void)doSomethingInClassN:(TextDisplay *)textDisplay {
    [textDisplay write:@"enter:doSomethingInClassN\n"];
    BSClassO * classO = [BSClassO new];
    [classO doSomethingO:textDisplay];
    [textDisplay write:@"exit:doSomethingInClassN\n"];
}
@end

@interface BSClassM : NSObject
- (void)doSomethingM:(TextDisplay *)textDisplay;
@end

@implementation BSClassM
- (void)doSomethingM:(TextDisplay *)textDisplay {
    [textDisplay write:@"enter:doSomethingM\n"];
    [[BSClassN class] doSomethingInClassN:textDisplay];
    [textDisplay write:@"exit:doSomethingM\n"];
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.textView.textColor = [UIColor lightGrayColor];
    self.textView.font = [UIFont systemFontOfSize:14];
    self.textView.editable = NO;
    self.textView.scrollEnabled = YES;

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textView resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)write:(NSString *)text {
    self.textView.text = [self.textView.text stringByAppendingString:text];
}

- (IBAction)justGoAction:(id)sender {
    self.textView.text = @"";
    ViewTextDisplay * textDisplay = [ViewTextDisplay new];
    [textDisplay set:self];
    [textDisplay write:@"enter:justGoAction\n"];
    BSClassM * classM = [BSClassM new];
    [classM doSomethingM:textDisplay];
    [textDisplay write:@"exit:justGoAction\n"];
}
@end
