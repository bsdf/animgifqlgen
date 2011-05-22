/*
 
 MIT license
 
 Copyright (c) 2009 Darren Ford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 
 Note that QL's display types are very limited.  You can only use text or html
 in order to generate the preview.  
 
 This plugin generates an HTML page representation containing the image, and
 uses QLPreviewRequestSetDataRepresentation to tell QuickLook to render the
 page as a QuickLook presentation.
 
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool *pool;
    NSString *html;
	NSMutableDictionary *props;
	
    pool = [[NSAutoreleasePool alloc] init];

	// Attempt to parse the image.  If it fails, so do we.
	NSImage *im = [[[NSImage alloc] initWithContentsOfURL:(NSURL *)url] autorelease];
	if (im != nil)
	{
		NSArray *reps = [im representations];
		if (reps != nil && [reps count] > 0)
		{
			// Should only generate content if the GIF image appears to contain images.
			
			// Potentially someone could craft a malicious GIF file here that contains
			// nasties, and then when the file is selected for quicklook, the HTML
			// page embedded in the QuickLook window contains the nasty.
			
			// As such, we check potential cases of maliciousness :-
			// 1. File MUST be able to be classified as an image by NSImage
			// 2. File MUST contain at least one (valid) bitmap representation.
			
			// WebKit will check during its rendering of the created HTML that
			// the image provided is a valid image as well.
			
			NSBitmapImageRep *rep = [[im representations] objectAtIndex: 0];
			if (rep != nil)
			{
				//int num_frames = [[rep valueForProperty:NSImageFrameCount] intValue];
				// If you think you might get something other than a bitmap image representation,
				// check for it here.
				
				// Grab out the size of the image representation -- we'll tell QuickLook to
				// make this the default size for the window.
				NSSize size = NSMakeSize ([rep pixelsWide], [rep pixelsHigh]);
				
				// Before proceeding make sure the user didn't cancel the request
				if (QLPreviewRequestIsCancelled(preview))
				{
					return noErr;
				}
				
				// Create a temporary HTML page that holds the GIF image.
				NSString *urlString = [(NSURL *)url absoluteString];
                
                props=[[[NSMutableDictionary alloc] init] autorelease];
                       
				[props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
				[props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
				[props setObject:[NSNumber numberWithFloat:(size.width)] forKey:(NSString *)kQLPreviewPropertyWidthKey];
				[props setObject:[NSNumber numberWithFloat:(size.height)] forKey:(NSString *)kQLPreviewPropertyHeightKey];
                
                NSError *error = nil;
                
                CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);
                CFURLRef url = CFBundleCopyResourceURL(bundle,
                                                       CFSTR("img"),
                                                       CFSTR("html"),
                                                       NULL);

                html = [NSString stringWithContentsOfURL:(NSURL *)url
                                                encoding:NSUTF8StringEncoding 
                                                   error:&error];
                
                if (error)
                {
                    html = [NSString stringWithString:[error localizedDescription]];
                }
                else 
                {
                    html = [html stringByReplacingOccurrencesOfString:@"%%bgcolor%%"
                                                           withString:@"black"];
                    
                    html = [html stringByReplacingOccurrencesOfString:@"%%imageurl%%"
                                                           withString:urlString];
                    
                    if (size.height < size.width) 
                    {
                        html = [html stringByReplacingOccurrencesOfString:@"%%heightorwidth%%" 
                                                               withString:@"width: 100%;"];
                    }
                    else
                    {
                        html = [html stringByReplacingOccurrencesOfString:@"%%heightorwidth%%" 
                                                               withString:@"height: 100%;"];
                    }
                }
                
				QLPreviewRequestSetDataRepresentation(preview, 
                                                      (CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                                      kUTTypeHTML,
                                                      (CFDictionaryRef)props);
			}
		}
	}
	
    [pool release];
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
