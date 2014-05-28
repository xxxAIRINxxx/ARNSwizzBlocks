//
//  ASBViewController.m
//  ARNSwizzBlocksDemo
//
//  Created by Airin on 2014/05/27.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ASBViewController.h"
#import "NSObject+ARNSwizzBlocks.h"
#import "ARNSwizzBlockTestObject.h"

@interface ASBViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation ASBViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder])) { return nil; }
    
    [self arn_swizzRespondsToSelector:@selector(tableView:cellForRowAtIndexPath:) fromProtocol:@protocol(UITableViewDataSource) usingBlock:^UITableViewCell *(id obj, UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *cellIdentifier = @"cellIdentifier";
        UITableViewCell *cell           = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell) {
            cell                     = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.selectionStyle      = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = @"Swizz!";
        
        return cell;
    }];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)tapOriginButton:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"test" message:@"Origin" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
}

- (IBAction)tapSwizzButton:(id)sender
{
    __weak typeof(self) weakSelf = self;
    [self arn_swizzRespondsToSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate) usingBlock:^(id obj, UIAlertView *alertView, NSInteger buttonIndex) {
        NSLog(@"obj : %@", obj);
        NSLog(@"alertView : %@", alertView);
        NSLog(@"buttonIndex : %d", (unsigned int)buttonIndex);
        
        ARNSwizzBlockTestObject *testObj = ARNSwizzBlockTestObject.new;
        [testObj arn_swizzRespondsToSelector:@selector(testingWithString:number:) fromProtocol:nil usingBlock:^(id obj, NSString *aString, NSNumber *aNumber) {
            NSLog(@"obj : %@", obj);
            NSLog(@"aString : %@", aString);
            NSLog(@"aNumber : %d", aNumber.intValue);
        }];
        
        [testObj testingWithString:@"test" number:@555];
        
        [weakSelf arn_swizzRemoveBlockForSelector:@selector(alertView:clickedButtonAtIndex:)];
        [[[UIAlertView alloc] initWithTitle:@"test" message:@"Swizz Remove" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
        
    }];
    [[[UIAlertView alloc] initWithTitle:@"test" message:@"Swizz" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    NSLog(@"Call Original clickedButtonAtIndex");
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 30;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return nil;
//}

@end
