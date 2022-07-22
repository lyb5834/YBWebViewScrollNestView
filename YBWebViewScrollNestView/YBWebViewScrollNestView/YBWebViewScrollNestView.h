//
//  YBWebViewScrollNestView.h
//  YBWebViewScrollNestView
//
//  Created by liyuanbo on 2022/5/26.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol YBWebViewScrollNestViewContainerDelegate <NSObject>

@optional
/**
 webViewHeight 默认是父视图的高度
 */
- (CGFloat)webViewHeight;
/**
 tableViewHeight 默认是父视图的高度
 */
- (CGFloat)tableViewHeight;
/**
 tableView最小高度 1~tableViewHeight 0 代表自适应 默认0
 */
- (CGFloat)minimumTableViewHeight;

@required
- (WKWebView *)webViewInContainer;
/**
 tableView backgroundColor会置成透明色 且 改tableview 不能添加 tableHeaderView
 */
- (UITableView *)tableViewInContainer;

@end


@interface YBWebViewScrollNestView : UIView
/**
 webView 是否可视 KVO enable
 */
@property (nonatomic, assign, readonly) BOOL isWebViewVisible;
/**
 tableView 是否可视 KVO enable
 */
@property (nonatomic, assign, readonly) BOOL isTableViewVisible;

- (instancetype)initWithDelegate:(id<YBWebViewScrollNestViewContainerDelegate>)delegate;
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<YBWebViewScrollNestViewContainerDelegate>)delegate;
/**
 滚动到顶部、底部、tableView位置，必须等网页加载完了调用！！！
 */
- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)scrollToTableViewAnimated:(BOOL)animated;
- (void)reloadView;

@end
