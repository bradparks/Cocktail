/*
	This file is part of Cocktail http://www.silexlabs.org/groups/labs/cocktail/
	This project is © 2010-2011 Silex Labs and is released under the GPL License:
	This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (GPL) as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. 
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	To read the license please visit http://www.gnu.org/copyleft/gpl.html
*/
package cocktail.core.linebox;

import cocktail.core.background.BackgroundManager;
import cocktail.core.css.CoreStyle;
import cocktail.core.dom.Document;
import cocktail.core.dom.Node;
import cocktail.core.geom.GeomUtils;

import cocktail.core.geom.GeomData;
import cocktail.core.layer.LayerRenderer;
import cocktail.core.renderer.ElementRenderer;
import cocktail.core.graphics.GraphicsContext;
import cocktail.core.utils.FastNode;
import cocktail.port.NativeElement;
import cocktail.core.layout.LayoutData;

/**
 * 
 * This is the base class for line boxes, which are elements which can be
 * liad on a line, like text.
 * 
 * Those line boxes are created by ElementRenderers as needed during inline
 * formatting
 * 
 * For instance, an InlineBoxRenderer will generate as many LineBox as the number
 * of lines where one of its children is.
 * For the text, a TextRenderer will generate as many TextLineBox as there is words,
 * spaces, tabs... in its text.
 * 
 * The line boxes are then stored by the BlockBoxRenderer establishing the inline
 * formatting context the line box participates in.
 * They are stored on the BlockBoxRenderer as an array of RootLineBox, each item
 * representing one line of the inline formatting context.
 * 
 * Each RootLineBox has line box children which are stored as a tree, as some
 * line box, like line boxes created by InlineBoxRenderer can have child line
 * boxes of their own.
 * 
 * LineBox extends Node so that its child can be stored as a tree
 * 
 * @author Yannick DOMINGUEZ
 */
class LineBox extends FastNode<LineBox>
{
	/**
	 * A reference to the element renderer which created this
	 * line box
	 */
	public var elementRenderer(default, null):ElementRenderer;
	
	/**
	 * the bounds of the line box, in the space of its containing
	 * block (the block which started the inline formatting context)
	 */
	public var bounds(get_bounds, null):RectangleVO;
	
	/**
	 * the ascent of the line box with its leading applied
	 */
	public var leadedAscent:Float;
	
	/**
	 * the descent of the line box with its leading applied
	 */
	public var leadedDescent:Float;
	
	/**
	 * the left margin of the line box
	 */
	public var marginLeft:Float;
	
	/**
	 * the right margin of the line box
	 */
	public var marginRight:Float;
	
	/**
	 * the left padding of the line box
	 */
	public var paddingLeft:Float;
	
	/**
	 * the right margin of the line box
	 */
	public var paddingRight:Float;
	
	/**
	 * class constructor. Init class attributes
	 */
	public function new(elementRenderer:ElementRenderer) 
	{
		super();
		
		bounds = new RectangleVO();
		
		this.elementRenderer = elementRenderer;
		
		marginLeft = 0;
		marginRight = 0;
		paddingLeft = 0;
		paddingRight = 0;
		
		leadedAscent = getLeadedAscent();
		leadedDescent = getLeadedDescent();
	}
	
	/**
	 * cleanup method
	 */
	public function dispose():Void
	{
		//bounds = null;
		elementRenderer = null;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PUBLIC RENDERING METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Render this LineBox using the provided
	 * graphic context as canvas
	 * 
	 * Default is to draw the background of the line box, this
	 * is expected behaviour for line boxes generated by an InlineBoxRenderer
	 */
	public function render(graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		//update children bounds
		getLineBoxesBounds(this, bounds);
		
		//bounds.width = _childrenBounds.width;
		//bounds.height = _childrenBounds.height;
		bounds.x = bounds.x + elementRenderer.globalBounds.x - scrollOffset.x;
		bounds.y = elementRenderer.globalBounds.y - scrollOffset.y;
		
		BackgroundManager.render(graphicContext, bounds, elementRenderer.coreStyle, elementRenderer, clipRect);
	}
		
	//////////////////////////////////////////////////////////////////////////////////////////
	// PUBLIC HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Wether this is a TextLineBox
	 */
	public function isText():Bool
	{
		return false;
	}
	
	/**
	 * Helper method to determine if this
	 * line box wraps a space character
	 */
	public function isSpace():Bool
	{
		return false;
	}
	
	/**
	 * Wheter the line box is a 
	 * place holder for an absolutely
	 * positioned element to determine
	 * its static position
	 */
	public function isStaticPosition():Bool
	{
		return false;
	}
	
	/**
	 * Wether the line box represents
	 * an embeded asset such as a picture
	 */
	public function isEmbedded():Bool
	{
		return false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PUBLIC FORMATTING METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	//TODO 4 : doc + missing values for vertical align
	//TODO 2 : messy , don't work properly
	public function getBaselineOffset(parentBaselineOffset:Float, parentXHeight:Float):Float
	{
		return parentBaselineOffset;
		//var coreStyle:CoreStyle = elementRenderer.coreStyle;
		//var baselineOffset:Float = parentBaselineOffset + coreStyle.getAbsoluteLength(coreStyle.computedValues.verticalAlign);
//
		//
		//switch (coreStyle.getKeyword(coreStyle.computedValues.verticalAlign))
		//{
			//case MIDDLE:
				//baselineOffset -=  (bounds.height / 2) - (parentXHeight / 2);
				//
			//case TOP:
				//
			//default:	
		//}
		//
		//return baselineOffset;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Retrieve all the bounds of the child line box
	 */
	private function getLineBoxesBounds(rootLineBox:LineBox, bounds:RectangleVO):Void
	{
		var child:LineBox = rootLineBox.firstChild;
		while(child != null)
		{
			//absolutely positioned line box are not used to compute the
			//bounds of the root line box
			if (child.isStaticPosition() == false)
			{
				GeomUtils.addBounds(child.bounds, bounds);
				
				if (child.firstChild != null)
				{
					getLineBoxesBounds(child, bounds);
				}
			}
			
			child = child.nextSibling;
		}
	}
	
	/**
	 * Return the leaded ascent of the line box
	 */
	private function getLeadedAscent():Float 
	{
		return 0;
	}
	
	/**
	 * Return the leaded descent of the line box
	 */
	private function getLeadedDescent():Float 
	{
		return 0;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// SETTERS/GETTERS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	private function get_bounds():RectangleVO
	{
		return bounds;
	}
}