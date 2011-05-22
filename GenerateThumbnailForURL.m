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

#include <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
 
   Most of this code came straight from Apple's example plugins.  There's nothing
   overly clever here!
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	NSImage *image = [[[NSImage alloc] initWithContentsOfURL:(NSURL *)url] autorelease];
	if (image != nil)
	{
		NSData* cocoaData = [NSBitmapImageRep TIFFRepresentationOfImageRepsInArray: [image representations]];
		CFDataRef carbonData = (CFDataRef)cocoaData;
		CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData(carbonData, NULL);
		// instead of the NULL above, you can fill a CFDictionary full of options
		// but the default values work for me
		CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
		// again, instead of the NULL above, you can fill a CFDictionary full of options if you want
		//What about different representations, can those be saved?
		QLThumbnailRequestSetImage(thumbnail, cgImage, NULL);
		CFRelease( imageSourceRef );
	}
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
