//
//  equalities.c
//  ZoneStar
//
//  Created by Armand Obreja on 07/25/2014.
//  Copyright (c) 2014 Armand Obreja. All rights reserved.
//

#include "equalities.h"

BOOL MKCoordinateSpanEqualToSpan(MKCoordinateSpan span1, MKCoordinateSpan span2)
{
    if (&span1 == NULL && &span2 == NULL) {
        return YES;
    }
    else if (&span1 == NULL || &span2 == NULL) {
        return NO;
    }
    return (span1.latitudeDelta == span2.latitudeDelta)
    && (span1.longitudeDelta == span2.longitudeDelta);
}

BOOL CLLocationCoordinate2DEqualToCoordinate(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2)
{
    if (&coord1 == NULL && &coord2 == NULL) {
        return YES;
    }
    else if (&coord1 == NULL || &coord2 == NULL) {
        return NO;
    }
    return (coord1.latitude == coord2.latitude) && (coord1.longitude == coord2.longitude);
}

BOOL MKCoordinateRegionEqualToRegion(MKCoordinateRegion region1, MKCoordinateRegion region2)
{
    if (&region1 == NULL && &region2 == NULL) {
        return YES;
    }
    else if (&region1 == NULL || &region2 == NULL) {
        return NO;
    }
    return MKCoordinateSpanEqualToSpan(region1.span, region2.span) && CLLocationCoordinate2DEqualToCoordinate(region1.center, region2.center);
}
