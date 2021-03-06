#import "TKDConfiguration.h"
#import "TKDFileUtilities.h"

#import "TKDEnsureAppSupportUpdated.h"
#import "TKDInstallRuby.h"
#import "TKDRubyBinary.h"

@interface TKDEnsureAppSupportUpdated(InstallationTasks)
-(void) installRubiesBundled;
-(void) installGemsBundled;
-(void) installBinariesBundled;
-(void) applyRubyConfigPatches;
-(void) guaranteeRubySymlinkToCurrent;
@end

@implementation TKDEnsureAppSupportUpdated

@synthesize view = _view;

-(TKDEnsureAppSupportUpdated *) initWithView:(id <TKDAppSupportEnsure>)view {
    if (self = [super init]) {
        _view = view;
		_rubyInstallationTasks = [[NSMutableArray alloc] init];
	}
    
	return self;
}

-(Class) configuration {
    return [TKDConfiguration self];
}

-(Class) fileManager {
    return [TKDFileUtilities self];
}

-(void) execute {
    [self installRubiesBundled];
    [self installGemsBundled];
    [self installBinariesBundled];
    [self applyRubyConfigPatches];
    
    [self guaranteeRubySymlinkToCurrent];
    
    [_view finished_ensuring_app_support_is_updated];
}

-(void) installRubiesBundled {
	NSArray *rubiesBundled = [[self configuration] rubiesBundled];
	
	TKDInstallRuby *installation;
    
    [_view checking_ruby_installation];
    [self.fileManager createDirectoryAtPathIfNonExistant:[[self configuration] rubiesInstalledDirectoryPath]];
    
    [_view finished_checking_ruby_installation];
    [_view finding_rubies_bundled];
    
	for (TKDRubyBinary *rb in rubiesBundled) {
        if ([rb isNotInstalled]) {
            [_view found_ruby_not_installed:rb];
            installation = [[TKDInstallRuby alloc] initWithRubyBinary:rb withView:_view];
            [installation install];
            [_view ruby_installed];
            [_rubyInstallationTasks addObject:installation];
		}
	}
    [_view finished_ruby_installations];
}

-(void) guaranteeRubySymlinkToCurrent {
    TKDRubyBinary *binary = [[TKDRubyBinary alloc] initWithName:[[self configuration] rubyVersion]];
    TKDInstallRuby *current = [[TKDInstallRuby alloc] initWithRubyBinary:binary withView:_view];

    [current symlink];
}

-(void) installGemsBundled {
    NSString *gemsGlobalInstalledDirectoryPath = [[self configuration] gemsGlobalInstalledDirectoryPath];
    NSString *bundledGemsZipfile = [[self configuration] bundledGemsFile];
	
    [_view checking_gems_installation];
    [self.fileManager createDirectoryAtPathIfNonExistant:gemsGlobalInstalledDirectoryPath];
    [_view unzipping_gems_bundled];
    [self.fileManager unzipFileAtPath:bundledGemsZipfile
                      inDirectoryPath:[[self configuration] tokaidoLocalHomeDirectoryPath]];
    [_view finished_unzipping_gems_bundled];
}

-(void) installBinariesBundled {
    NSString *binariesInstalledDirectoryPath = [[self configuration] binariesInstalledDirectoryPath];
	NSString *bundledBinariesfile = [[self configuration] bundledBinariesFile];
	
    [_view checking_binaries_installation];
    [self.fileManager createDirectoryAtPathIfNonExistant:binariesInstalledDirectoryPath];
    [_view unzipping_binaries_bundled];
    [self.fileManager unzipFileAtPath:bundledBinariesfile
                      inDirectoryPath:[[self configuration] tokaidoLocalHomeDirectoryPath]];
    [_view finished_unzipping_binaries_bundled];
}

-(void) applyRubyConfigPatches {
    [_view starting_clang_search];
    if ([self.fileManager fileExists:@"/usr/bin/clang"]) {
        [_view starting_clang_symlink];
        [self.fileManager createDirectoryAtPathIfNonExistant:[self.configuration compilerInstalledDirectoryPath]];
        
        NSTask *linkTask = [[NSTask alloc] init];
        [linkTask setLaunchPath:@"/bin/ln"];
        [linkTask setCurrentDirectoryPath:[self.configuration compilerInstalledDirectoryPath]];
        [linkTask setArguments:@[ @"-f", @"-s", @"/usr/bin/clang", @"clang" ] ];
        [linkTask launch];
        [_view finished_clang_symlink];
    } else {
        [_view clang_not_found];
    }
    
    NSTask *linkTask = [[NSTask alloc] init];
    [linkTask setLaunchPath:@"/bin/ln"];
    [linkTask setCurrentDirectoryPath:NSHomeDirectory()];
    [linkTask setArguments:@[ @"-f", @"-s", [self.configuration magickInstalledDirectoryPath], @".magick" ] ];
    [linkTask launch];
}

-(NSArray *) rubyInstallations {
    return [NSArray arrayWithArray:[_rubyInstallationTasks copy]];
}

@end
