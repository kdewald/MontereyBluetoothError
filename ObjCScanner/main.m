//
//  main.m
//  ObjCScanner
//
//  Created by Kevin Dewald on 1/23/22.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

@interface AdapterBaseMacOS : NSObject<CBCentralManagerDelegate>
- (instancetype)init;
- (void)scanStart;
- (void)scanStop;
- (bool)scanIsActive;
@end

@interface AdapterBaseMacOS () {}
// Private properties
@property(strong) dispatch_queue_t centralManagerQueue;
@property(strong) CBCentralManager* centralManager;
// Private methods
- (void)validateCentralManagerState;
@end

@implementation AdapterBaseMacOS

- (instancetype)init {
    self = [super init];
    if (self) {
        // TODO: Review dispatch_queue attributes to see if there's a better way to handle this.
        _centralManagerQueue = dispatch_queue_create("AdapterBaseMacOS.centralManagerQueue", DISPATCH_QUEUE_SERIAL);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_centralManagerQueue options:nil];
        //_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];

        // Validate authorization state of the central manager.
        if (CBCentralManager.authorization != CBManagerAuthorizationAllowedAlways) {
            // TODO: Convert to error.
            NSLog(@"Application does not have Bluetooth authorization.\n");
        } else {
            NSLog(@"Application does have Bluetooth authorization.\n");
        }

        [NSThread sleepForTimeInterval:0.400];
        NSLog(@"Init Ready");
    }
    return self;
}

- (void)validateCentralManagerState {
    // Validate the central manager state by checking if it is powered on for up to 5 seconds.
    NSDate* endDate = [NSDate dateWithTimeInterval:5.0 sinceDate:NSDate.now];
    while (self.centralManager.state != CBManagerStatePoweredOn && [NSDate.now compare:endDate] == NSOrderedAscending) {
        [NSThread sleepForTimeInterval:0.01];
    }

    if (self.centralManager.state != CBManagerStatePoweredOn) {
        NSException* myException = [NSException exceptionWithName:@"CBManagerNotPoweredException"
                                                           reason:@"CBManager is not powered on."
                                                         userInfo:nil];
        // TODO: Append current state to exception.
        @throw myException;
    }
}

- (void)scanStart {
    NSLog(@"ScanStart");
    [self validateCentralManagerState];
    [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
    if (!self.centralManager.isScanning) {
        NSLog(@"Did not start scanning!\n");
        // TODO: Should an exception be thrown here?
    }
}

- (void)scanStop {
    NSLog(@"ScanStop");
    [self.centralManager stopScan];
}

- (bool)scanIsActive {
    return [self.centralManager isScanning];
}

- (void)centralManagerDidUpdateState:(CBCentralManager*)central {
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@"CBManagerStateUnknown!\n");
            break;
        case CBManagerStateResetting:
            NSLog(@"CBManagerStateResetting!\n");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"CBManagerStateUnsupported!\n");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"CBManagerStateUnauthorized!\n");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"CBManagerStatePoweredOff!\n");
            // NOTE: Notify the user that the Bluetooth adapter is turned off.
            break;
        case CBManagerStatePoweredOn:
            // NOTE: This state is required to be able to operate CoreBluetooth.
            NSLog(@"CBManagerStatePoweredOn!\n");
            break;
    }
}

- (void)centralManager:(CBCentralManager*)central
    didDiscoverPeripheral:(CBPeripheral*)peripheral
        advertisementData:(NSDictionary<NSString*, id>*)advertisementData
                     RSSI:(NSNumber*)RSSI {
    NSLog(@"Peripheral Discovered");
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"Hello, World!");
        
        AdapterBaseMacOS* adapter = [[AdapterBaseMacOS alloc] init];
        [adapter scanStart];
        [NSThread sleepForTimeInterval:5.00];
        [adapter scanStop];
    }
    return 0;
}
