//
//  YBWebViewScrollNestView.m
//  YBWebViewScrollNestView
//
//  Created by liyuanbo on 2022/5/26.
//

#import "YBWebViewScrollNestView.h"

@interface YBWebViewScrollNestView ()

@property (nonatomic, strong) WKWebView * webView;
@property (nonatomic, strong) YBNestTableView * tableView;
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

- (void)loadView
{
    self.webView = [self.delegate webViewInContainer];
    [self addSubview:self.webView];
    
    self.tableView = [self.delegate tableViewInContainer];
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

- (void)reloadView
{
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


@implementation YBNestTableView

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    BOOL ret = [super pointInside:point withEvent:event];
    if (CGRectContainsPoint(self.tableHeaderView.frame, point)) {
        return NO;
    }
    return ret;
}

@end
