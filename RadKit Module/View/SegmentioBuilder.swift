//
//  SegmentioBuilder.swift
//  Master
//
//  Created by Sina khanjani on 9/29/19.
//  Copyright © 2019 iPersianDeveloper. All rights reserved.
//


import Segmentio
import UIKit

struct SegmentioBuilder {
    /*
     static func setupBadgeCountForIndex(_ segmentioView: Segmentio, index: Int) {
     segmentioView.addBadge(
     at: index,
     count: 10,
     color: ColorPalette.coral
     )
     }
     */
    static func buildSegmentioView(content:[SegmentioItem],segmentioView: Segmentio, segmentioStyle: SegmentioStyle, segmentioPosition: SegmentioPosition = .fixed(maxVisibleItems: 3)) {
        segmentioView.setup(
            content: content,
            style: segmentioStyle,
            options: segmentioOptions(segmentioStyle: segmentioStyle, segmentioPosition: segmentioPosition)
        )
    }
    
    private static func segmentioOptions(segmentioStyle: SegmentioStyle, segmentioPosition: SegmentioPosition = .fixed(maxVisibleItems: 3)) -> SegmentioOptions {
        var imageContentMode = UIView.ContentMode.center
        switch segmentioStyle {
        case .imageBeforeLabel, .imageAfterLabel:
            imageContentMode = .scaleAspectFit
        default:
            break
        }
        
        return SegmentioOptions(
            backgroundColor: .clear,
            segmentPosition: segmentioPosition,
            scrollEnabled: true,
            indicatorOptions: segmentioIndicatorOptions(),
            horizontalSeparatorOptions: segmentioHorizontalSeparatorOptions(),
            verticalSeparatorOptions: segmentioVerticalSeparatorOptions(),
            imageContentMode: imageContentMode,
            labelTextAlignment: .center,
            labelTextNumberOfLines: 1,
            segmentStates: segmentioStates(),
            animationDuration: 0.3
        )
    }
    
    private static func segmentioStates() -> SegmentioStates {
        let font = UIFont.persianFont(size: 17)
        return SegmentioStates(
            defaultState: segmentioState(
                backgroundColor: .clear,
                titleFont: font,
                titleTextColor: .white
            ),
            selectedState: segmentioState(
                backgroundColor:.clear,
                titleFont: font,
                titleTextColor: #colorLiteral(red: 0, green: 0.7249298692, blue: 0.6760887504, alpha: 1)
            ),
            highlightedState: segmentioState(
                backgroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                titleFont: font,
                titleTextColor: #colorLiteral(red: 0.1344881654, green: 0.1894396544, blue: 0.2187974453, alpha: 1)
            )
        )
    }
    
    private static func segmentioState(backgroundColor: UIColor, titleFont: UIFont, titleTextColor: UIColor) -> SegmentioState {
        return SegmentioState(
            backgroundColor: backgroundColor,
            titleFont: titleFont,
            titleTextColor: titleTextColor
        )
    }
    
    private static func segmentioIndicatorOptions() -> SegmentioIndicatorOptions {
        return SegmentioIndicatorOptions(
            type: .bottom,
            ratio: 1,
            height: 5,
            color: #colorLiteral(red: 0, green: 0.7249298692, blue: 0.6760887504, alpha: 1)
        )
    }
    
    private static func segmentioHorizontalSeparatorOptions() -> SegmentioHorizontalSeparatorOptions {
        return SegmentioHorizontalSeparatorOptions(
            type: .topAndBottom,
            height: 0.3,
            color: #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        )
    }
    
    private static func segmentioVerticalSeparatorOptions() -> SegmentioVerticalSeparatorOptions {
        return SegmentioVerticalSeparatorOptions(
            ratio: 1,
            color: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        )
    }    
}
