/* IncomingCallViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "IncomingCallViewController.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"

@implementation IncomingCallViewController

@synthesize addressLabel;
@synthesize avatarImage;
@synthesize call;


#pragma mark - Lifecycle Functions

- (id)init {
    return [super initWithNibName:@"IncomingCallViewController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(callUpdateEvent:) 
                                                 name:@"LinphoneCallUpdate" 
                                               object:nil];
    [self callUpdate:call state:linphone_call_get_state(call)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                 name:@"LinphoneCallUpdate" 
                                               object:nil];
}



#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification*)notif {  
    LinphoneCall *acall = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState astate = [[notif.userInfo objectForKey: @"state"] intValue];
    [self callUpdate:acall state:astate];
}


#pragma mark - 

- (void)callUpdate:(LinphoneCall *)acall state:(LinphoneCallState)astate {  
    if(call == acall && (astate == LinphoneCallEnd || astate == LinphoneCallError)) {
        [self dismiss: [NSNumber numberWithInt: IncomingCall_Aborted]];
    }
}


#pragma mark - Property Functions

- (void)setCall:(LinphoneCall*)acall {
    call = acall;
    [self update];
}

- (void)update {
    [self view]; //Force view load
    
    UIImage *image;
    NSString* address;
    const LinphoneAddress* addr = linphone_call_get_remote_address(call);
    if (addr != NULL) {
        // contact name 
        const char* lAddress = linphone_address_as_string_uri_only(addr);
        const char* lDisplayName = linphone_address_get_display_name(addr);
        const char* lUserName = linphone_address_get_username(addr);
        if (lDisplayName) 
            address = [NSString stringWithUTF8String:lDisplayName];
        else if(lUserName) 
            address = [NSString stringWithUTF8String:lUserName];
        if(lAddress) {
            NSString *address = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
            image = [FastAddressBook getContactImage:contact thumbnail:false];
        }
    } else {
        [addressLabel setText:@"Unknown"];
    }
    
    // Set Image
    if(image == nil) {
        image = [UIImage imageNamed:@"avatar_unknown.png"];
    }
    [avatarImage setImage:image];
    
    // Set Address
    if(address == nil) {
        address = @"Unknown";
    }
    [addressLabel setText:address];
}

- (LinphoneCall*) getCall {
    return call;
}


#pragma mark - Action Functions

- (IBAction)onAcceptClick:(id)event {
    linphone_core_accept_call([LinphoneManager getLc], call);
    [self dismiss: [NSNumber numberWithInt:IncomingCall_Accepted]];
}

- (IBAction)onDeclineClick:(id)event {
    linphone_core_terminate_call([LinphoneManager getLc], call);
    [self dismiss: [NSNumber numberWithInt:IncomingCall_Decline]];
}

@end
