Include Strix

/// File(name) related functions
Class Strix.Lib.File Extends %RegisteredObject
{

/// Returns a unique filename based on the name passed in, by appending a sequence
/// number if the file already exists.
ClassMethod UniqueFilename(Filename As %String, Output Changed As %Boolean) As %String
{
	Set Changed = 0
	Set NewName = Filename
	Set Index = 0
	
	While ##class(%File).Exists(NewName) {
		Set Changed = 1
		Set Index = Index + 1
		
		;Determine filename part
		Set Name = ##class(%File).GetFilename(Filename)
		;Don't use %File:GetDirectory as it expands the directory (with $ZU(12))
		Set Dir = $Extract(Filename, 1, $Length(Filename) - $Length(Name))
		
		If Name [ "." {
			;Filename has extension: insert sequence before it
			Set Name = $Piece(Name, ".", 1, $Length(Name, ".") - 1)_"_"_Index_"."_$Piece(Name, ".", $Length(Name, "."))
		} Else {
			;No extension: just append sequence
			Set Name = Name_"_"_Index
		}
		
		;Put directory back
		Set NewName = Dir_Name
	}
	
	Quit NewName
}

/// Appends one or more path components to an existing path. Allows more
/// than one path component to be appended at once.
ClassMethod AppendPath(Path As %String, SubPaths... As %String) As %String
{
	Set Result = Path
	
	; Directory separator for current OS
	Set Sep = $$$DirSep
	
	; What we accept as directory separator (Windows API accepts both \ and /)
	Set Accept = $Select($$$isWINDOWS:"\/", 1: "/")
	
	For i = 1:1:$Get(SubPaths) {
		Set SubPath = $Get(SubPaths(i))
		If SubPath = "" Continue
		If Accept '[ $Extract(Result, *) Set Result = Result_Sep
		Set Result = Result_SubPath
	}
	
	Quit Result
}

/// Split Path into ParentDir and LastPiece, where LastPiece is the last pathname
/// component and ParentDir is everything leading up to that. If Path is already
/// at the root, returns false.
ClassMethod SplitPath(Path As %String, Output ParentDir As %String, Output LastPiece As %String) As %Boolean
{
	Set ParentDir = ##class(%File).ParentDirectoryName(Path)
	If ParentDir = Path Quit 0
	
	Set Len = ##class(%File).GetDirectoryLength(Path)
	Set LastPiece = ##class(%File).GetDirectoryPiece(Path, Len)
	
	Quit 1
}

/// Returns a boolean indicating whether a path is absolute (true) or
/// relative (false). If AllowFromRoot is true, a path like "\dir\sub"
/// (i.e., without a drive) is considered absolute; by default it is not.
ClassMethod IsPathAbsolute(Path As %String, AllowFromRoot As %Boolean = 0) As %Boolean
{
#if $$$isWINDOWS
	;Windows allows forwards slashes as paths separators in system calls
	Set Path = $Replace(Path, "/", "\")
	;Rooted from drive:
	If $Extract(Path, 2, 3) = ":\" Quit 1
	;Network or extended path syntax
	If $Extract(Path, 1, 2) = "\\" Quit 1
	;Path from root; still depends on current drive
	If $Extract(Path) = "\" Quit ''AllowFromRoot
	
#elseif $$$isUNIX
	If $Extract(Path) = "/" Quit 1
	
#else
	SET $ECODE=",Uunsupported operating system,"
	
#endif
	
	Quit 0
}

/// Makes sure the directory for the given filename exists
ClassMethod EnsureDirectory(Filename As %String) As %Status
{
	Set Dir = ##class(%File).GetDirectory(Filename)
	If ##class(%File).DirectoryExists(Dir) Quit $$$OK
	
	Set ok = ##class(%File).CreateDirectoryChain(Dir, .rc)
	If 'ok Quit $$$BuildStatus("Error {} creating directory '{}'.", rc, Dir)
	
	Quit $$$OK
}

}

