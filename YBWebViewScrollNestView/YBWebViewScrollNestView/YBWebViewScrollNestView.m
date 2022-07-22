//
//  YBWebViewScrollNestView.m
//  YBWebViewScrollNestView
//
//  Created by liyuanbo on 2022/5/26.
//

#import "YBWebViewScrollNestView.h"
#import <objc/runtime.h>

@interface UITableView (YBEvent)

@property (nonatomic, assign) BOOL disableHeaderResponse;

@end

@implementation UITableView (YBEvent)

+ (void)load
{
    SEL originSelector = @selector(pointInside:withEvent:);
    SEL newSelector = @selector(yb_pointInside:withEvent:);
    YBExchangeImplementationsInTwoClasses([self class], originSelector, [self class], newSelector);
}

- (BOOL)yb_pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event
{
    BOOL ret = [self yb_pointInside:point withEvent:event];
    if (self.disableHeaderResponse) {
        if (CGRectContainsPoint(self.tableHeaderView.frame, point)) {
            return NO;
        }
    }
    return ret;
}

BOOL
YBExchangeImplementationsInTwoClasses(Class _fromClass, SEL _originSelector, Class _toClass, SEL _newSelector) {
    if (!_fromClass || !_toClass) {
        return NO;
    }
    
    Method oriMethod = class_getInstanceMethod(_fromClass, _originSelector);
    Method newMethod = class_getInstanceMethod(_toClass, _newSelector);
    if (!newMethod) {
        return NO;
    }
    
    BOOL isAddedMethod = class_addMethod(_fromClass, _originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        // 如果 class_addMethod 成功了，说明之前 fromClass 里并不存在 originSelector，所以要用一个空的方法代替它，以避免 class_replaceMethod 后，后续 toClass 的这个方法被调用时可能会 crash
        IMP oriMethodIMP = method_getImplementation(oriMethod) ?: imp_implementationWithBlock(^(id selfObject) {});
        const char *oriMethodTypeEncoding = method_getTypeEncoding(oriMethod) ?: "v@:";
        class_replaceMethod(_toClass, _newSelector, oriMethodIMP, oriMethodTypeEncoding);
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
    return YES;
}

- (BOOL)disableHeaderResponse
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setDisableHeaderResponse:(BOOL)disableHeaderResponse
{
    objc_setAssociatedObject(self, @selector(disableHeaderResponse), @(disableHeaderResponse), OBJC_ASSOCIATION_ASSIGN);
}

@end



@interface YBWebViewScrollNestView ()

@property (nonatomic, weak) WKWebView * webView;
@property (nonatomic, weak) UITableView * tableView;
@property (nonatomic, weak) id<YBWebViewScrollNestViewContainerDelegate> delegate;
@property (nonatomic, strong) UIView * tableHeaderView;
@property (nonatomic, assign) BOOL isWebViewVisible;
@property (nonatomic, assign) BOOL isTableViewVisible;

@end

@implementation YBWebViewScrollNestView

- (void)dealloc
{
    [self removeContentSizeObserver];
    [self removeContentOffsetObserver];
}

- (instancetype)initWithDelegate:(id<YBWebViewScrollNestViewContainerDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self loadView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<YBWebViewScrollNestViewContainerDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;
        [self loadView];
    }
    return self;
}

- (void)reloadView
{
    [self updateFrames];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    [self.webView.scrollView setContentOffset:CGPointMake(0, 0) animated:animated];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    [self.webView.scrollView setContentOffset:CGPointMake(0, self.webView.scrollView.contentSize.height + self.webView.scrollView.contentInset.bottom - self.webView.frame.size.height) animated:animated];
}

- (void)scrollToTableViewAnimated:(BOOL)animated
{
    CGPoint contentOffset = CGPointMake(0, self.webView.scrollView.contentSize.height);
    if (self.webView.scrollView.contentInset.bottom < self.webView.frame.size.height) {
        contentOffset = CGPointMake(0, self.webView.scrollView.contentSize.height - (self.webView.frame.size.height - self.webView.scrollView.contentInset.bottom));
    }
    [self.webView.scrollView setContentOffset:contentOffset animated:animated];
}

#pragma mark - privites

- (void)loadView
{
    self.webView = [self.delegate webViewInContainer];
    [self addSubview:self.webView];
    
    self.tableView = [self.delegate tableViewInContainer];
    self.tableView.disableHeaderResponse = YES;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = self.tableHeaderView;
    [self addSubview:self.tableView];
    
    [self addContentSizeObserver];
    [self addContentOffsetObserver];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateFrames];
}

- (void)updateFrames
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewHeight)]) {
        self.webView.frame = CGRectMake(0, 0, self.bounds.size.width, self.delegate.webViewHeight);
    }else {
        self.webView.frame = self.bounds;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableViewHeight)]) {
        self.tableView.frame = CGRectMake(0, 0, self.bounds.size.width, self.delegate.tableViewHeight);
    }else {
        self.tableView.frame = self.bounds;
    }
}

- (void)setContainerContentInset
{
    CGFloat contentHeight = self.tableView.contentSize.height - self.webView.scrollView.contentSize.height;
    
    CGFloat minimumTableViewHeight = 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(minimumTableViewHeight)]) {
        minimumTableViewHeight = self.delegate.minimumTableViewHeight;
    }
    if (minimumTableViewHeight > self.tableView.bounds.size.height) {
        minimumTableViewHeight = self.tableView.bounds.size.height;
    }
    if (minimumTableViewHeight == 0) {
        minimumTableViewHeight = contentHeight;
    }
    if (contentHeight < minimumTableViewHeight) {
        self.tableView.contentInset =
        UIEdgeInsetsMake(self.tableView.contentInset.top,
                         self.tableView.contentInset.left,
                         minimumTableViewHeight - contentHeight,
                         self.tableView.contentInset.right);
    }
    
    if (self.webView.scrollView.contentSize.height == self.tableView.contentSize.height) {
        //tableView 没有数据
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }else {
        self.webView.scrollView.contentInset =
        UIEdgeInsetsMake(self.webView.scrollView.contentInset.top,
                         self.webView.scrollView.contentInset.left,
                         MAX(minimumTableViewHeight, contentHeight),
                         self.webView.scrollView.contentInset.right);
    }
    [self analysisContentOffset];
}

- (void)analysisContentOffset
{
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height - self.webView.bounds.size.height;
    CGFloat currentContentHeight = self.webView.scrollView.contentOffset.y;
    if (currentContentHeight <= webViewContentHeight) {
        self.isWebViewVisible = YES;
        self.isTableViewVisible = NO;
    }else if (currentContentHeight > self.webView.scrollView.contentSize.height) {
        self.isWebViewVisible = NO;
        self.isTableViewVisible = YES;
    }else {
        self.isWebViewVisible = YES;
        self.isTableViewVisible = YES;
    }
}

#pragma mark - Observers
- (void)addContentSizeObserver
{
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 context:nil];
    [self.tableView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 context:nil];
}

- (void)removeContentSizeObserver
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)addContentOffsetObserver
{
    [self.webView.scrollView addObserver:self
                              forKeyPath:@"contentOffset"
                                 options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                 context:nil];
    [self.tableView addObserver:self
                     forKeyPath:@"contentOffset"
                        options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                        context:nil];
}

- (void)removeContentOffsetObserver
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.webView.scrollView && [keyPath isEqualToString:@"contentSize"]) {

        if ([change[NSKeyValueChangeNewKey] CGSizeValue].height == [change[NSKeyValueChangeOldKey] CGSizeValue].height ) {return;}
        CGFloat contentHeight = [change[NSKeyValueChangeNewKey] CGSizeValue].height;
        [self.tableHeaderView setFrame:CGRectMake(0, 0, self.tableView.frame.size.width, contentHeight)];
        [self.tableView beginUpdates];
        self.tableView.tableHeaderView = self.tableHeaderView;
        [self.tableView endUpdates];
        
        [self setContainerContentInset];
    }else if (object == self.tableView && [keyPath isEqualToString:@"contentSize"]) {
        
        if ([change[NSKeyValueChangeNewKey] CGSizeValue].height == [change[NSKeyValueChangeOldKey] CGSizeValue].height ) { return; }
        
        [self setContainerContentInset];
    }else if (object == self.tableView && [keyPath isEqualToString:@"contentOffset"]) {
        
        if ([change[NSKeyValueChangeNewKey] CGPointValue].y == [change[NSKeyValueChangeOldKey] CGPointValue].y) { return; }
        
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        [self removeContentOffsetObserver];
        self.webView.scrollView.contentOffset = contentOffset;
        [self addContentOffsetObserver];
        [self analysisContentOffset];
    }else if (object == self.webView.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
         
        if ([change[NSKeyValueChangeNewKey] CGPointValue].y == [change[NSKeyValueChangeOldKey] CGPointValue].y) { return; }
        
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        [self removeContentOffsetObserver];
        self.tableView.contentOffset = contentOffset;
        [self addContentOffsetObserver];
        [self analysisContentOffset];
    }
}

#pragma mark - lazyloads
- (UIView *)tableHeaderView
{
    if (!_tableHeaderView) {
        _tableHeaderView = [UIView new];
        _tableHeaderView.backgroundColor = [UIColor clearColor];
        _tableHeaderView.userInteractionEnabled = NO;
    }
    return _tableHeaderView;
}

@end
