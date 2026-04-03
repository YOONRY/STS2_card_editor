using System;
using System.Collections.Generic;
using HarmonyLib;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Models.Cards;

namespace AnimeWaifuSilent.AnimeWaifuSilentCode;

[HarmonyPatch(/*Could not decode attribute arguments.*/)]
public static class CardPortraitReplacementPatch
{
	private static readonly Dictionary<System.Type, string> Replacements;

	private static bool Prefix(CardModel __instance, ref string __result)
	{
		string text = default(string);
		if (Replacements.TryGetValue(((object)__instance).GetType(), ref text))
		{
			__result = text;
			return false;
		}
		return true;
	}

	static CardPortraitReplacementPatch()
	{
		Dictionary<System.Type, string> obj = new Dictionary<System.Type, string>();
		obj.Add(typeof(Accelerant), "res://AnimeWaifuSilent/card_portraits/silent/accelerant.png");
		obj.Add(typeof(Accuracy), "res://AnimeWaifuSilent/card_portraits/silent/accuracy.png");
		obj.Add(typeof(Acrobatics), "res://AnimeWaifuSilent/card_portraits/silent/acrobatics.png");
		obj.Add(typeof(Adrenaline), "res://AnimeWaifuSilent/card_portraits/silent/adrenaline.png");
		obj.Add(typeof(Afterimage), "res://AnimeWaifuSilent/card_portraits/silent/afterimage.png");
		obj.Add(typeof(BladeDance), "res://AnimeWaifuSilent/card_portraits/silent/blade_dance.png");
		obj.Add(typeof(Blur), "res://AnimeWaifuSilent/card_portraits/silent/blur.png");
		obj.Add(typeof(BulletTime), "res://AnimeWaifuSilent/card_portraits/silent/bullet_time.png");
		obj.Add(typeof(CalculatedGamble), "res://AnimeWaifuSilent/card_portraits/silent/calculated_gamble.png");
		obj.Add(typeof(DaggerThrow), "res://AnimeWaifuSilent/card_portraits/silent/dagger_throw.png");
		obj.Add(typeof(Dash), "res://AnimeWaifuSilent/card_portraits/silent/dash.png");
		obj.Add(typeof(DefendSilent), "res://AnimeWaifuSilent/card_portraits/silent/defend_silent.png");
		obj.Add(typeof(Distraction), "res://AnimeWaifuSilent/card_portraits/silent/distraction.png");
		obj.Add(typeof(Envenom), "res://AnimeWaifuSilent/card_portraits/silent/envenom.png");
		obj.Add(typeof(Expertise), "res://AnimeWaifuSilent/card_portraits/silent/expertise.png");
		obj.Add(typeof(Expose), "res://AnimeWaifuSilent/card_portraits/silent/expose.png");
		obj.Add(typeof(FanOfKnives), "res://AnimeWaifuSilent/card_portraits/silent/fan_of_knives.png");
		obj.Add(typeof(Finisher), "res://AnimeWaifuSilent/card_portraits/silent/finisher.png");
		obj.Add(typeof(FlickFlack), "res://AnimeWaifuSilent/card_portraits/silent/flick_flack.png");
		obj.Add(typeof(Footwork), "res://AnimeWaifuSilent/card_portraits/silent/footwork.png");
		obj.Add(typeof(GrandFinale), "res://AnimeWaifuSilent/card_portraits/silent/grand_finale.png");
		obj.Add(typeof(InfiniteBlades), "res://AnimeWaifuSilent/card_portraits/silent/infinite_blades.png");
		obj.Add(typeof(Malaise), "res://AnimeWaifuSilent/card_portraits/silent/malaise.png");
		obj.Add(typeof(MementoMori), "res://AnimeWaifuSilent/card_portraits/silent/memento_mori.png");
		obj.Add(typeof(Murder), "res://AnimeWaifuSilent/card_portraits/silent/murder.png");
		obj.Add(typeof(Neutralize), "res://AnimeWaifuSilent/card_portraits/silent/neutralize.png");
		obj.Add(typeof(Nightmare), "res://AnimeWaifuSilent/card_portraits/silent/nightmare.png");
		obj.Add(typeof(NoxiousFumes), "res://AnimeWaifuSilent/card_portraits/silent/noxious_fumes.png");
		obj.Add(typeof(Outmaneuver), "res://AnimeWaifuSilent/card_portraits/silent/outmaneuver.png");
		obj.Add(typeof(PiercingWail), "res://AnimeWaifuSilent/card_portraits/silent/piercing_wail.png");
		obj.Add(typeof(Prepared), "res://AnimeWaifuSilent/card_portraits/silent/prepared.png");
		obj.Add(typeof(Reflex), "res://AnimeWaifuSilent/card_portraits/silent/reflex.png");
		obj.Add(typeof(Skewer), "res://AnimeWaifuSilent/card_portraits/silent/skewer.png");
		obj.Add(typeof(Slice), "res://AnimeWaifuSilent/card_portraits/silent/slice.png");
		obj.Add(typeof(Strangle), "res://AnimeWaifuSilent/card_portraits/silent/strangle.png");
		obj.Add(typeof(StrikeSilent), "res://AnimeWaifuSilent/card_portraits/silent/strike_silent.png");
		obj.Add(typeof(Survivor), "res://AnimeWaifuSilent/card_portraits/silent/survivor.png");
		obj.Add(typeof(Tactician), "res://AnimeWaifuSilent/card_portraits/silent/tactician.png");
		obj.Add(typeof(TheHunt), "res://AnimeWaifuSilent/card_portraits/silent/the_hunt.png");
		obj.Add(typeof(WellLaidPlans), "res://AnimeWaifuSilent/card_portraits/silent/well_laid_plans.png");
		obj.Add(typeof(Alchemize), "res://AnimeWaifuSilent/card_portraits/colorless/alchemize.png");
		obj.Add(typeof(Panache), "res://AnimeWaifuSilent/card_portraits/colorless/panache.png");
		obj.Add(typeof(Apparition), "res://AnimeWaifuSilent/card_portraits/event/apparition.png");
		obj.Add(typeof(WraithForm), "res://AnimeWaifuSilent/card_portraits/event/wraith_form.png");
		obj.Add(typeof(AscendersBane), "res://AnimeWaifuSilent/card_portraits/curse/ascenders_bane.png");
		obj.Add(typeof(Fear), "res://AnimeWaifuSilent/card_portraits/necrobinder/fear.png");
		obj.Add(typeof(Void), "res://AnimeWaifuSilent/card_portraits/status/void.png");
		obj.Add(typeof(Infection), "res://AnimeWaifuSilent/card_portraits/status/infection.png");
		obj.Add(typeof(Shiv), "res://AnimeWaifuSilent/card_portraits/token/shiv.png");
		Replacements = obj;
	}
}
