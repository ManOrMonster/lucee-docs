component accessors=true {

	property name="tree"    type="array";
	property name="treeMap" type="struct";

	public any function init( required string rootDirectory ) {
		var pageFiles = _readPageFilesFromDocsDirectory( arguments.rootDirectory );

		tree      = [];
		treeMap   = {}

		_sortPageFilesByDepth( pageFiles );

		for( var pageFile in pageFiles ) {
			page = _preparePageObject( pageFile, arguments.rootDirectory );

			treeMap[ page.getId() ] = page;

			if ( treeMap.keyExists( page.getParentId() ) ) {
				treeMap[ page.getParentId() ].addChild( page );
				page.setParent( treeMap[ page.getParentId() ] )
			} else {
				tree.append( page );
			}
		}

		return this;
	}

	public any function getPage( required string id ) {
		return treeMap[ arguments.id ] ?: NullValue();
	}


// private helpers
	private array function _readPageFilesFromDocsDirectory( required string rootDirectory ) {
		var pageFiles = DirectoryList( arguments.rootDirectory, true, "path", "*.json" );

		pageFiles = pageFiles.map( function( path ){
			return path.replace( rootDirectory, "" );
		} );

		return pageFiles;
	}

	private void function _sortPageFilesByDepth( required array pageFiles ) {
		arguments.pageFiles.sort( function( page1, page2 ){
			var depth1 = page1.listLen( "\/" );
			var depth2 = page2.listLen( "\/" );

			if ( depth1 == depth2 ) {
				return page1 > page2 ? 1 : -1;
			}

			return depth1 > depth2 ? 1 : -1;
		} );
	}

	private any function _preparePageObject( required string pageFilePath, required string rootDirectory ) {
		var page = "";
		var pageData = new StructuredDataFileReader().readDataFile( arguments.rootDirectory & pageFilePath )

		switch( pageData.pageType ?: "" ) {
			case "function":
				page = new FunctionPage( argumentCollection=pageData );
			break;
			case "tag":
				page = new TagPage( argumentCollection=pageData );
			break;
			default:
				page = new Page( argumentCollection=pageData );
		}

		page.setId( _getPageIdFromJsonFilePath( arguments.pageFilePath ) );
		page.setParentId( _getParentPageIdFromPageId( page.getId() ) );
		page.setChildren( [] );
		page.setDepth( ListLen( page.getId(), "/" ) );

		return page;
	}

	private string function _getPageIdFromJsonFilePath( required string filePath ) {
		var withoutExtension = ReReplace( arguments.filePath, "\.json$", "" );
		var parts            = withoutExtension.listToArray( "\/" );

		if ( parts.len() > 1 && parts[ parts.len() ] == parts[ parts.len()-1 ] ) {
			parts.deleteAt( parts.len() );
		}

		return "/" & parts.toList( "/" );
	}

	private string function _getParentPageIdFromPageId( required string pageId ) {
		var parts = arguments.pageId.listToArray( "/" );
		parts.deleteAt( parts.len() );

		return "/" & parts.toList( "/" );
	}
}