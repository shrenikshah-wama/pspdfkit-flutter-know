package com.pspdfkit.flutter.pspdfkit

 import android.content.Context
 import com.pspdfkit.ui.toolbar.ContextualToolbar
 import com.pspdfkit.ui.toolbar.grouping.presets.MenuItem
 import com.pspdfkit.ui.toolbar.grouping.presets.PresetMenuItemGroupingRule

 class CustomAnnotationToolbarMenu(context: Context) : PresetMenuItemGroupingRule(context) {
     override fun getGroupPreset(capacity: Int, itemsCount: Int): List<MenuItem> {
         return listOf(
             MenuItem(com.pspdfkit.R.id.pspdf__annotation_creation_toolbar_item_highlight),
             MenuItem(com.pspdfkit.R.id.pspdf__annotation_creation_toolbar_item_underline),
//             MenuItem(com.pspdfkit.R.id.pspdf__annotation_creation_toolbar_item_picker),
//             MenuItem(com.pspdfkit.R.id.pspdf__annotation_creation_toolbar_item_note),
         )
     }
 }