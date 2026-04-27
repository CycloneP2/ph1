// Tweak.mm - EDGY HACKS (STABILITY FIX + ESP LINE)
// Optimized for MLBB - CORRECTED FOR STABILITY

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

// Dynamic Hooking Helper
void edgy_hook(void *target, void *replacement, void **original) {
    void *h = dlsym(RTLD_DEFAULT, "MSHookFunction");
    if (!h) h = dlsym(RTLD_DEFAULT, "TITANOX_HOOK_FUNCTION");
    if (!h) h = dlsym(RTLD_DEFAULT, "DobbyHook");
    if (h) {
        ((void(*)(void*, void*, void**))h)(target, replacement, original);
    }
}
#define MSHookFunction edgy_hook

// ============================================
// DATA STRUCTURES
// ============================================
typedef struct { float x, y, z; } Vector3;

// ============================================
// CONFIGURATION & OFFSETS (VALIDATED)
// ============================================
#define RVA_BATTLE_MANAGER_INST 0xADC8A0   
#define OFF_SHOW_PLAYERS        0x78        
#define OFF_SHOW_MONSTERS       0x80        
#define OFF_LOCAL_PLAYER        0x50        

#define OFF_ENTITY_POS          0x310       
#define OFF_ENTITY_CAMP         0xD8        
#define OFF_ENTITY_HP           0x1AC       
#define OFF_ENTITY_HP_MAX       0x1B0       
#define OFF_ENTITY_SHIELD       0x1B8       
#define OFF_PLAYER_HERO_NAME    0x918       

#define OFF_ENTITY_ID           0x194       
#define OFF_MINIMAP_VISIBLE     0x2AF       

#define RVA_WORLD_TO_SCREEN     0x89FE040   
#define RVA_CAMERA_MAIN         0x89FF130   

#define RVA_SDK_REPORT_LOG      0x4CEB580
#define RVA_SDK_REPORT_ERR      0x4CEB690

// Tweak State
static BOOL espEnabled = YES;
static BOOL monsterEsp = NO;
static BOOL snaplinesEnabled = YES;
static BOOL showTeam = NO;
static BOOL bypassDNS = YES;
static BOOL showHeroName = YES;
static float enemyR = 1.0, enemyG = 0.2, enemyB = 0.2; // Red for enemies

static uintptr_t g_unityBase = 0;

// ============================================
// UTILITIES
// ============================================

uintptr_t get_base(const char* name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* img = _dyld_get_image_name(i);
        if (img && strstr(img, name)) return (uintptr_t)_dyld_get_image_header(i);
    }
    return 0;
}

// Memory safety check
// Fix is_valid for arm64 iOS
bool is_valid(uintptr_t ptr) {
    return (ptr > 0x100000000 && ptr < 0x2000000000 && (ptr & 0x3) == 0);
}

// Safer String Reading
NSString* readIl2CppString(uintptr_t ptr) {
    if (!is_valid(ptr)) return nil;
    int len = *(int*)(ptr + 0x10);
    if (len <= 0 || len > 128) return nil;
    uintptr_t dataPtr = ptr + 0x14;
    if (!is_valid(dataPtr)) return nil;
    return [NSString stringWithCharacters:(uint16_t*)dataPtr length:len];
}

// ============================================
// ANTI-REPORT
// ============================================
static void (*old_Log)(void*);
void hooked_Log(void* m) { if (bypassDNS) return; old_Log(m); }

// ============================================
// UI & ESP RENDERER
// ============================================

@interface EdgyESPView : UIView
@end

@implementation EdgyESPView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(redraw)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)redraw { [self setNeedsDisplay]; }

void drawEntities(CGContextRef ctx, CGRect rect, uintptr_t list, void* cam, Vector3 (*w2s)(void*, Vector3), int myTeam, UIColor* color, BOOL isMonster) {
    if (!is_valid(list)) return;
    
    uintptr_t arrayPtr = *(uintptr_t*)(list + 0x10);
    int size = *(int*)(list + 0x18);
    if (size <= 0 || size > 50 || !is_valid(arrayPtr)) return;

    for (int i = 0; i < size; i++) {
        uintptr_t entity = *(uintptr_t*)(arrayPtr + 0x20 + (i * 8));
        if (!is_valid(entity)) continue;

        // Monster Filtering
        if (isMonster) {
            int m_id = *(int*)(entity + OFF_ENTITY_ID);
            if (m_id != 1001 && m_id != 1002 && m_id != 2001 && m_id != 3001) continue;
        }

        int team = *(int*)(entity + OFF_ENTITY_CAMP);
        if (!showTeam && team == myTeam && !isMonster) continue;

        int hp = *(int*)(entity + OFF_ENTITY_HP);
        int maxHp = *(int*)(entity + OFF_ENTITY_HP_MAX);
        if (hp <= 0 || hp > maxHp) continue;

        Vector3 pos = *(Vector3*)(entity + OFF_ENTITY_POS);
        Vector3 sPos = w2s(cam, pos);
        
        if (sPos.z > 1.0f) {
            float x = sPos.x;
            float y = rect.size.height - sPos.y;
            
            if (snaplinesEnabled) {
                CGContextSetStrokeColorWithColor(ctx, color.CGColor);
                CGContextSetLineWidth(ctx, 1.2);
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, rect.size.width/2, rect.size.height/2); // Center
                CGContextAddLineToPoint(ctx, x, y);
                CGContextStrokePath(ctx);
            }
            
            if (showHeroName && !isMonster) {
                NSString *name = readIl2CppString(*(uintptr_t*)(entity + OFF_PLAYER_HERO_NAME));
                if (name) [name drawAtPoint:CGPointMake(x-20, y-35) withAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:9]}];
            }
            
            [[NSString stringWithFormat:@"%d", hp] drawAtPoint:CGPointMake(x-10, y-20) withAttributes:@{NSForegroundColorAttributeName: color, NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    if (!espEnabled || !g_unityBase) return;
    
    @try {
        uintptr_t bmAddr = *(uintptr_t*)(g_unityBase + RVA_BATTLE_MANAGER_INST);
        if (!is_valid(bmAddr)) return;
        uintptr_t bm = *(uintptr_t*)bmAddr; 
        if (!is_valid(bm)) return;

        CGContextRef ctx = UIGraphicsGetCurrentContext();
        void* (*get_main)() = (void*(*)())(g_unityBase + RVA_CAMERA_MAIN);
        void* cam = get_main();
        if (!cam) return;
        
        Vector3 (*w2s)(void*, Vector3) = (Vector3(*)(void*, Vector3))(g_unityBase + RVA_WORLD_TO_SCREEN);
        uintptr_t local = *(uintptr_t*)(bm + OFF_LOCAL_PLAYER);
        int myTeam = (is_valid(local)) ? *(int*)(local + OFF_ENTITY_CAMP) : 0;
        
        UIColor *enemyColor = [UIColor colorWithRed:enemyR green:enemyG blue:enemyB alpha:1.0];
        
        // Draw Players
        uintptr_t pList = *(uintptr_t*)(bm + OFF_SHOW_PLAYERS);
        drawEntities(ctx, rect, pList, cam, w2s, myTeam, enemyColor, NO);
        
        // Draw Monsters
        if (monsterEsp) {
            uintptr_t mList = *(uintptr_t*)(bm + OFF_SHOW_MONSTERS);
            drawEntities(ctx, rect, mList, cam, w2s, myTeam, [UIColor yellowColor], YES);
        }
    } @catch (NSException *e) {}
}
@end

@interface EdgyMenuManager : NSObject
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *fab;
+ (instancetype)shared;
- (void)setupWithWindow:(UIWindow *)window;
- (void)toggleMenu;
- (void)swChanged:(UISwitch *)s;
- (void)handlePan:(UIPanGestureRecognizer *)p;
@end

@implementation EdgyMenuManager
+ (instancetype)shared {
    static EdgyMenuManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (void)setupWithWindow:(UIWindow *)window {
    // Add ESP Overlay
    EdgyESPView *espView = [[EdgyESPView alloc] initWithFrame:window.bounds];
    [window addSubview:espView];

    // Add FAB
    self.fab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fab.frame = CGRectMake(50, 150, 60, 60);
    self.fab.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.8 alpha:0.9];
    self.fab.layer.cornerRadius = 30;
    [self.fab setTitle:@"EDGY" forState:UIControlStateNormal];
    self.fab.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.fab addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.fab addGestureRecognizer:pan];
    [window addSubview:self.fab];
}

- (void)handlePan:(UIPanGestureRecognizer *)p {
    CGPoint translation = [p translationInView:self.fab.superview];
    self.fab.center = CGPointMake(self.fab.center.x + translation.x, self.fab.center.y + translation.y);
    [p setTranslation:CGPointZero inView:self.fab.superview];
}

- (void)toggleMenu {
    if (!self.menuView) {
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 320)];
        self.menuView.center = self.fab.superview.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.layer.borderWidth = 1.5;
        self.menuView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.8 alpha:1.0].CGColor;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 250, 30)];
        title.text = @"EDGY MOD MENU";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:16];
        [self.menuView addSubview:title];
        
        auto addToggle = [&](NSString* txt, BOOL *val, int y) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 150, 30)];
            lbl.text = txt;
            lbl.textColor = [UIColor whiteColor];
            lbl.font = [UIFont systemFontOfSize:14];
            [self.menuView addSubview:lbl];

            UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, y, 50, 30)];
            sw.on = *val;
            [sw addTarget:self action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
            objc_setAssociatedObject(sw, "ptr", [NSValue valueWithPointer:val], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self.menuView addSubview:sw];
        };
        
        addToggle(@"ESP Player", &espEnabled, 60);
        addToggle(@"ESP Monster", &monsterEsp, 100);
        addToggle(@"Snaplines", &snaplinesEnabled, 140);
        addToggle(@"Hero Name", &showHeroName, 180);
        addToggle(@"Show Team", &showTeam, 220);
        addToggle(@"Bypass DNS", &bypassDNS, 260);

        [self.fab.superview addSubview:self.menuView];
    } else {
        self.menuView.hidden = !self.menuView.hidden;
    }
}

- (void)swChanged:(UISwitch *)s {
    NSValue *val = objc_getAssociatedObject(s, "ptr");
    BOOL *ptr = (BOOL *)[val pointerValue];
    if (ptr) *ptr = s.on;
}
@end

__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        g_unityBase = get_base("UnityFramework");
        if (g_unityBase) {
            // Hook Anti-Report (DNS Bypass)
            /* 
            if (bypassDNS) {
                MSHookFunction((void*)(g_unityBase + RVA_SDK_REPORT_LOG), (void*)hooked_Log, (void**)&old_Log);
            }
            */
            
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow) {
                [[EdgyMenuManager shared] setupWithWindow:keyWindow];
            }
        }
    });
}
