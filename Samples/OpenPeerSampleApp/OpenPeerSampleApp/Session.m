/*
 
 Copyright (c) 2012, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "Session.h"
#import <OpenpeerSDK/HOPRolodexContact.h>
#import <OpenpeerSDK/HOPConversationThread.h>

@implementation Session

@synthesize conversationThread = _conversationThread;
- (id) initWithContact:(HOPRolodexContact*) inContact conversationThread:(HOPConversationThread*) inConverationThread
{
    self = [super init];
    if (self)
    {
        self.participantsArray = [[NSMutableArray alloc] init];
        [self.participantsArray addObject:inContact];
        self.messageArray = [[NSMutableArray alloc] init];
        self.unreadMessageArray = [[NSMutableArray alloc] init];
        self.sessionIdsHistory = [[NSMutableSet alloc] init];
        self.arrayMergedConversationThreads = [[NSMutableArray alloc] init];
    }
    self.conversationThread = inConverationThread;
    [self.sessionIdsHistory addObject:[inConverationThread getThreadId]];
    return self;
}

- (id) initWithContacts:(NSArray*) inContacts conversationThread:(HOPConversationThread*) inConverationThread
{
    self = [super init];
    if (self)
    {
        self.participantsArray = [[NSMutableArray alloc] init];
        if (inContacts)
            [self.participantsArray addObjectsFromArray:inContacts];
        self.messageArray = [[NSMutableArray alloc] init];
        self.unreadMessageArray = [[NSMutableArray alloc] init];
    }
    self.conversationThread = inConverationThread;
    [self.sessionIdsHistory addObject:[inConverationThread getThreadId]];
    return self;
}

- (void) setConversationThread:(HOPConversationThread *)inConversationThread
{
    @synchronized(self)
    {
        if (![self.arrayMergedConversationThreads containsObject:inConversationThread])
        {
            if (inConversationThread)
                [self.arrayMergedConversationThreads addObject:inConversationThread];
            else
                [self.arrayMergedConversationThreads removeAllObjects];
        }
        OPLog(HOPLoggerSeverityInformational, HOPLoggerLevelDebug, [NSString stringWithFormat:@"%@", (inConversationThread == _conversationThread ? [NSString stringWithFormat:@"Using same conversation thread %@",[inConversationThread getThreadId]] : [NSString stringWithFormat:@"Switched from %@ conversation thread to %@",[_conversationThread getThreadId],[inConversationThread getThreadId]])]);
        
        _conversationThread = inConversationThread;
    }
}

- (HOPConversationThread*) conversationThread
{
    HOPConversationThread* ret  = nil;
    @synchronized(self)
    {
        ret = _conversationThread;
    }
    
    return ret;
}
@end
