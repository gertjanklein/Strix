Include Strix.SCM

Class Strix.SCM.Studio Extends %Studio.Extension.Base
{

/// The menu item handler; delegates to an appropriate subclass of Strix.SCM.Handler.Base.
Property Handler As Strix.SCM.HandlerProxy;

// ===== Source control menu handling methods

/// Called when a menu item is to be displayed; determines what to display,
/// and whether the item should be enabled or not.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	Quit ..Handler.OnMenuItem(MenuName, InternalName, SelectedText, .Enabled, .DisplayName)
}

/// Called when a menu item is selected; depends what to do based on the
/// (internal) menu name, and performs that action. This usually entails
/// displaying some kind of dialog.
Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	Quit ..Handler.UserAction(Type, Name, InternalName, SelectedText, .Action, .Target, .Msg, .Reload)
}

/// Called after a menu item is selected and the appropriate dialog (if any)
/// has been displayed.
Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
	Quit ..Handler.AfterUserAction(Type, .Name, InternalName, Answer, Msg, .Reload)
}

// ===== Studio callbacks

/// Login method; use to instantiate delegator
Method Login(Name As %String, Password As %String) As %Status
{
	Set Credentials = $lb($g(Name), $g(Password))
	Set ..Handler = ##class(Strix.SCM.HandlerProxy).%New(Credentials)
	Quit $$$OK
}

// -----

// 

Method OnBeforeLoad(InternalName As %String) As %Status
{
	Quit ..Handler.OnBeforeLoad(InternalName)
}

Method OnAfterLoad(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit ..Handler.OnAfterLoad(InternalName, Object)
}

Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit ..Handler.OnBeforeSave(InternalName, Location, Object)
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	Quit ..Handler.OnAfterSave(InternalName, Object)
}

Method OnAfterStorage(InternalName As %String, Location As %String = "") As %Status
{
	Quit ..Handler.OnAfterStorage(InternalName, Location)
}

Method OnBeforeCompile(InternalName As %String, ByRef qstruct As %String) As %Status
{
	Quit ..Handler.OnBeforeCompile(InternalName, .qstruct)
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	Quit ..Handler.OnAfterCompile(InternalName)
}

Method OnBeforeDelete(InternalName As %String) As %Status
{
	Quit ..Handler.OnBeforeDelete(InternalName)
}

Method OnAfterDelete(InternalName As %String) As %Status
{
	Quit ..Handler.OnAfterDelete(InternalName)
}

// ===== Menu query implementations

/// Provide a list of the top level menu items that Studio will add when connecting to this namespace.
Query MainMenus(Classname As %String) As %Query(ROWSPEC = "Name:%String,Type:%String")
{
}

ClassMethod MainMenusExecute(ByRef qHandle As %Binary, Classname As %String) As %Status
{
	#dim Handler As Strix.SCM.Handler.Base
	Set Handler = ##class(Strix.SCM.Handler.Base).%New()
	Set qHandle = $lb(0, Handler.GetMainMenus(.Status))
	If 'Status Quit Status
	Quit $$$OK
}

ClassMethod MainMenusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = MainMenusExecute ]
{
	Set Index = $List(qHandle, 1) + 1, Items = $List(qHandle, 2)
	If $ListData(Items, Index) {
		Set Row = $List(Items, Index)
		Set $List(qHandle, 1) = Index
		
	} Else {
		Set Row = ""
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod MainMenusClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = MainMenusExecute ]
{
	Quit $$$OK
}

/// Query for the items in menu MenuName
Query MenuItems(ClassName As %String, MenuName As %String, InternalName As %String, SelectedText As %String) As %Query(ROWSPEC = "MenuItem_Name:%String,MenuItem_Enabled:%String,MenuItem_Save:%String,MenuItem_Separator:%String")
{
}

ClassMethod MenuItemsExecute(ByRef qHandle As %Binary, ClassName As %String, MenuName As %String, InternalName As %String, SelectedText As %String) As %Status
{
	#dim Handler As Strix.SCM.Handler.Base
	Set Status = ##class(Strix.SCM.Project).GetHandler(InternalName, .Handler)
	If 'Status Quit Status
	Set qHandle = $lb(0, Handler.GetMenuItems(MenuName, InternalName, SelectedText, .Status))
	If 'Status Quit Status
	Quit $$$OK
}

ClassMethod MenuItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = MenuItemsExecute ]
{
	Set Index = $List(qHandle, 1) + 1, Items = $List(qHandle, 2)
	If $ListData(Items, Index) {
		Set Row = $List(Items, Index)
		Set $List(qHandle, 1) = Index
		
	} Else {
		Set Row = ""
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod MenuItemsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = MenuItemsExecute ]
{
	Quit $$$OK
}

}

