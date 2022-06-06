//
//  MYTableView.h
//  YBWebViewScrollNestView
//
//  Created by liyuanbo on 2022/6/6.
//

#import <UIKit/UIKit.h>
#import "YBWebViewScrollNestView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MYTableView : UITableView
<
//遵循此协议即可，此协议无任何实现方法
YBNestTableViewProtocol
>

@end

NS_ASSUME_NONNULL_END
