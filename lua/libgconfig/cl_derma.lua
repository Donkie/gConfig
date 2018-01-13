
local PANEL = {}
AccessorFunc( PANEL, "m_sPlaceholderText", 	"PlaceholderText", FORCE_STRING )
function PANEL:Init()
	self.PlaceholderText = vgui.Create( "DLabel", self )
		self.PlaceholderText:Dock( FILL )
		self.PlaceholderText:DockMargin( 3, 1, 3, 0 )
		self.PlaceholderText:SetMouseInputEnabled( false )
		self.PlaceholderText:SetText( "" )
		self.PlaceholderText:SetWrap( true )
		self.PlaceholderText:SetTextColor( Color( 169, 169, 169 ) )
		self.PlaceholderText:SetContentAlignment( 4 )
		self.PlaceholderText.PerformLayout = function( self )
			self:SetContentAlignment( self:GetParent():IsMultiline() and 7 or 4 )
			self.m_colText.a = self:GetParent():GetText() == "" and 255 or 0

			DLabel.PerformLayout( self )
		end

	self:SetPlaceholderText( "" )
end

function PANEL:SetPlaceholderText( strValue )
	self.m_sPlaceholderText = tostring( strValue )
	self.PlaceholderText:SetText( self.m_sPlaceholderText )
end

function PANEL:PerformLayout(w, h)
	self.PlaceholderText:InvalidateLayout()

	DTextEntry.PerformLayout(self, w, h)
end

vgui.Register("DTextEntryPlaceholder", PANEL, "DTextEntry")
