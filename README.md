ARNSwizzBlocks
======================

[![Build Status](https://travis-ci.org/xxxAIRINxxx/ARNSwizzBlocks.svg?branch=master)](https://travis-ci.org/xxxAIRINxxx/ARNSwizzBlocks)

I aimed at the implementation of ReactiveCocoa Signal Message Forwarding.


Features
============

Features of ARNSwizzBlocks is the following

* Method Swizzling of Instance Method.

* Method Swizzling Influence range is Only Instance Object. 

Respect
============

It was inspired by the following products.

* [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)

* [REKit](https://github.com/zuccoi/REKit)


Requirements
============

Requires iOS 7.0 or later, and uses ARC.


How To Use
============

### Method Swizzle
```objectivec

@property (nonatomic, weak) IBOutlet UITableView *tableView;

...

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self arn_swizzRespondsToSelector:@selector(tableView:cellForRowAtIndexPath:) fromProtocol:@protocol(UITableViewDataSource) usingBlock:^UITableViewCell *(id obj, UITableView *tableView, NSIndexPath *indexPath) {
    	// Call!!
        static NSString *cellIdentifier = @"cellIdentifier";
        UITableViewCell *cell           = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (!cell) {
            cell                     = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.selectionStyle      = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = @"Swizz!";
        
        return cell;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Not Call
    return nil;
}

```

```objectivec

- (IBAction)tapSwizzButton:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test" message:@"Swizz" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [self arn_swizzRespondsToSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate) usingBlock:^(id obj, UIAlertView *alertView, NSInteger buttonIndex) {
    	// Call!!
    }];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Not Call
}

```


Licensing
============

The source code is distributed under the nonviral MIT License.

 It's the simplest most permissive license available.


Japanese Note
============ 

ReactiveCocoaのMessage Forwarding機構を参考にして、

既存インスタンスメソッドの差し替えを行うカテゴリを作りました。

インスタンスメソッドの差し替えは、差し替えたインスタンスのみにか反映されないようにしています。	


ReactiveCocoaの実装に関しては、以下の解説を参考にさせていただきました。

http://qiita.com/ikesyo/items/9c6b00e2b00d8f5e3e11


検証が甘いので、ご使用はお勧め出来ません。。

