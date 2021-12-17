( function _Namespace_s_()
{

'use strict';

const _ = _global_.wTools;
_.censor = _.censor || Object.create( null );


// --
// profile hook handlers
// --

function profileHookPathMake( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( profileHookPathMake, o );
  _.assert( _.str.defined( o.type ), 'Expects type {-o.type-}' );

  self._profileNameMapFromDefaults( o );

  const baseName = `${ o.type.replace( /^\w/, o.type[ 0 ].toUpperCase() ) }Hook`;
  const hookRelativePath = _.path.join( o.storageDir, o.profileDir, self.storageHookDir, `${ baseName }.js` );
  return _.fileProvider.configUserPath( hookRelativePath );
}

profileHookPathMake.defaults =
{
  ... _.censor.profileNameMapFrom.defaults,
  type : null,
};

//

function profileHookGet( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( profileHookGet, o );

  self._profileNameMapFromDefaults( o );

  _.assert( _.str.defined( o.type ), 'Expects type {-o.type-}' );

  const hooksMap =
  {
    git : _profileGitHook,
    npm : _profileNpmHook,
    cargo : _profileCargoHook,
    ssh : _profileSshHook,
  };

  const o2 = _.mapOnly_( null, o, self.profileHookPathMake.defaults );

  if( o.type === 'super' )
  {
    const result = [];
    for( let type in hooksMap )
    result.push( hookGet( type ) );
    return result;
  }
  else
  {
    return hookGet( o.type );
  }

  /* */

  function hookGet( type )
  {
    o2.type = type;
    let filePath = self.profileHookPathMake( o2 );
    if( _.fileProvider.fileExists( filePath ) )
    return _.fileProvider.fileRead( filePath );
    else
    return hooksMap[ type ].toString();
  }
}

profileHookGet.defaults =
{
  ... _.censor.profileNameMapFrom.defaults,
  type : null,
};

//

function profileHookSet( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( profileHookSet, o );
  _.assert( _.str.defined( o.hook ), 'Expects hook.' );

  self._profileNameMapFromDefaults( o );

  _.assert( _.str.defined( o.type ), 'Expects type {-o.type-}' );

  const o2 = _.mapOnly_( null, o, self.profileHookPathMake.defaults );

  if( o.type === 'super' )
  {
    let types = [ 'git', 'npm', 'cargo', 'ssh' ];
    for( let i = 0 ; i < types.length ; i++ )
    hookMake( o.hook, types[ i ] );
  }
  else
  {
    hookMake( o.hook, o.type );
  }

  /* */

  function hookMake( data, type )
  {
    o2.type = type;
    const filePath = self.profileHookPathMake( o2 );
    _.fileProvider.fileWrite({ filePath, data });
  }
}

profileHookSet.defaults =
{
  ... _.censor.profileNameMapFrom.defaults,
  hook : null,
  type : null,
};

//

function _profileGitHook( identity, options )
{
  const start = _.process.starter
  ({
    mode : 'shell',
    outputCollecting : 1,
    throwingExitCode : 0,
    inputMirroring : 0,
    sync : 1,
  });

  const login = identity[ 'git.login' ] || identity.login;
  const email = identity[ 'git.email' ] || identity.email;
  _.assert( _.str.defined( login ) );
  _.assert( _.str.defined( email ) );
  const oldName = start({ execPath : 'git config --global user.name', outputPiping : 0 }).output.trim();
  if( oldName )
  {
    start
    ({
      execPath :
      [
        `git config --global --unset url.https://${ oldName }@github.com.insteadof`,
        `git config --global --unset url.https://${ oldName }@bitbucket.org.insteadof`,
      ],
    });
  }
  start
  ({
    execPath :
    [
      `git config --global user.name "${ login }"`,
      `git config --global user.email "${ email }"`,
      `git config --global url."https://${ login }@github.com".insteadOf "https://github.com"`,
      `git config --global url."https://${ login }@bitbucket.org".insteadOf "https://bitbucket.org"`,
    ],
    throwingExitCode : 1,
  });

  if( options.logger )
  start
  ({
    execPath :  'git config --global --list --show-origin',
    logger : options.logger,
    outputPiping : 1,
    throwingExitCode : 1,
  });
}

//

function _profileNpmHook( identity, options )
{
  const tempPath = _.path.tempOpen( 'npmHook' );
  const start = _.process.starter
  ({
    currentPath : tempPath,
    mode : 'shell',
    outputCollecting : 1,
    throwingExitCode : 1,
    inputMirroring : 0,
    sync : 1,
  });

  const login = identity[ 'npm.login' ] || identity.login;
  const email = identity[ 'npm.email' ] || identity.email;
  const token = identity[ 'npm.token' ] || identity.token;
  const password = process.env.NPM_PASS;
  _.assert( _.str.defined( login ) );
  _.assert( _.str.defined( email ) );
  _.assert( _.str.defined( token ) );
  _.assert( _.str.defined( password ), 'Expects password as environment variable {-NPM_PASS-}' );

  start( 'npm i npm-cli-login' );
  const npmCli = _.path.nativize( './node_modules/.bin/npm-cli-login' );
  start
  ({
    execPath : `${ npmCli } -u ${ login } -p ${ password } -e ${ email } --quotes`,
    outputPiping : 0,
    outputCollecting : 0,
  });

  if( options.logger )
  start
  ({
    execPath : 'npm profile get --json',
    outputPiping : 1,
    logger : options.logger,
  });
  _.path.tempClose( tempPath );
}

//

function _profileCargoHook( identity, options )
{
}

//

function _profileSshHook( identity, options )
{
  _.assert( _.str.defined( identity[ 'ssh.path' ], 'Expects path to identity keys' ) );

  const keysPath = _.fileProvider.configUserPath( identity[ 'ssh.path' ] );
  const originalPath = _.fileProvider.configUserPath( '.ssh' );
  const backupPath = _.fileProvider.configUserPath( '.ssh.backup' );

  _.fileProvider.filesDelete( backupPath );
  _.fileProvider.filesReflect({ reflectMap : { [ originalPath ] : backupPath } });

  _.fileProvider.filesDelete( originalPath );
  _.fileProvider.filesReflect({ reflectMap : { [ keysPath ] : originalPath } });

  _.process.starter
  ({
    execPath : 'ssh-add -D',
    mode : 'shell',
    outputCollecting : 1,
    throwingExitCode : 1,
    inputMirroring : 0,
    sync : 1,
  });
}

//

function profileHookCallWithIdentity( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( profileHookCallWithIdentity, o );
  _.assert( _.aux.is( o.identity ), 'Expects identity {-o.identity-}.' );

  o.logger = _.logger.relativeMaybe( o.logger, -3 );
  self._profileNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.profileHookPathMake.defaults );
  const hooksMap =
  {
    git : _profileGitHook,
    npm : _profileNpmHook,
    cargo : _profileCargoHook,
    ssh : _profileSshHook,
  };

  _.assert( o.identity.type in hooksMap, `Unknown type ${ o.identity.type }.` );

  o2.type = o.identity.type;
  let filePath = self.profileHookPathMake( o2 );

  if( _.fileProvider.fileExists( filePath ) )
  hookCall( filePath );
  else
  hooksMap[ o.identity.type ]( o.identity, o );

  /* */

  function hookCall( filePath )
  {
    filePath = _.path.nativize( filePath );
    const routine = require( filePath );
    _.assert( _.routine.is( routine ) );

    let result = routine.call( _, o.identity, o );
    if( _.promiseIs( result ) )
    result = _.Consequence.From( result );
    if( _.consequenceIs( result ) )
    result = result.deasync().sync();

    delete require.cache[ filePath ];
    return result;
  }
}

profileHookCallWithIdentity.defaults =
{
  ... _.censor.profileNameMapFrom.defaults,
  identity : null,
  logger : 2,
};

// --
// declare
// --

let Extension =
{
  profileHookPathMake,
  profileHookGet,
  profileHookSet,
  profileHookCallWithIdentity,

  // fields

  storageHookDir : 'hook',
};

Object.assign( _.censor, Extension );

//

if( typeof module !== 'undefined' )
module[ 'exports' ] = _global_.wTools;

})();
