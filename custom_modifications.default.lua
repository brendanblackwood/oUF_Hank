local cfg = oUF_Hank_config
oUF_Hank_hooks = {}

--[[

	Your custom modifications go here. Every function of the main addon can be hooked into.

	Examples:
	____________________________________________

		Absolute health number for player frame
		----------------------------------------------------------------------
		oUF_Hank_hooks.PlayerHealth = {
			sharedStyle = function(self, unit)
				if unit == "player" then self:Tag(self.power, "[hpDetailed] || [ppDetailed]") end
			end,
		}
		----------------------------------------------------------------------


		Health-colored percentage
		----------------------------------------------------------------------
		oUF_Hank_hooks.HealthColored = {
			UpdateHealth = function(self)
				if self.unit == "player" and UnitHasVehicleUI("player") then
					h, hMax = UnitHealth("pet"), UnitHealthMax("pet")
				else
					h, hMax = UnitHealth(self.unit), UnitHealthMax(self.unit)
				end

				if UnitIsConnected(self.unit) and not UnitIsGhost(self.unit) and not UnitIsDead(self.unit) then
					for i = 1, 4 do
						self.healthFill[5 - i]:SetVertexColor(1 - h / hMax, h / hMax, 0)
					end
				end
			end,
		}
		----------------------------------------------------------------------


		Suppress OmniCC
		----------------------------------------------------------------------
		oUF_Hank_hooks.NoOmniCC = {
			PostCreateIcon = function(icons, icon)
				icon.cd.noCooldownCount = true
			end,
		}
		----------------------------------------------------------------------
}

]]

oUF_Hank_hooks.YOUR_MODIFICATION = {

}