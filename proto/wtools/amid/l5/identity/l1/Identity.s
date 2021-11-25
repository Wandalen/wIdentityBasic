( function _Namespace_s_()
{

'use strict';

const _ = _global_.wTools;
_.identity = _.identity || Object.create( null );

// --
// identity
// --

function identityCopy( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument.' );
  _.routine.options( identityCopy, o );
  _.assert( _.str.defined( o.identitySrcName ), 'Expects defined option {-o.identitySrcName-}.' );
  _.assert( _.str.defined( o.identityDstName ), 'Expects defined option {-o.identityDstName-}.' );
  _.assert( !_.path.isGlob( o.identityDstName ), 'Expects no globs' );

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  o2.selector = o.identitySrcName;
  const identity = self.identityGet( o2 );
  _.assert( _.map.is( identity ), `Selected no identity : ${ o.identitySrcName }. Please, improve selector.` );
  _.assert
  (
    ( 'login' in identity || `${ identity.type }.login` in identity ) && 'type' in identity,
    `Selected ${ _.props.keys( identity ).length } identity(s). Please, improve selector.`
  );

  const o3 = _.mapOnly_( null, o, self.identityNew.defaults );
  identity.name = o.identityDstName;
  o3.identity = identity;

  self.identityNew( o3 );
}

identityCopy.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  identitySrcName : null,
  identityDstName : null,
  force : false,
};

//

function identityGet( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );

  if( _.str.is( arguments[ 0 ] ) )
  o = { profileDir : arguments[ 0 ] };
  _.routine.options( identityGet, o );

  _.censor._configNameMapFromDefaults( o );

  if( o.selector === null )
  o.selector = '';
  _.assert( _.str.is( o.selector ) );
  o.selector = `identity/${ o.selector }`;

  return _.censor.configGet( o );
}

identityGet.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  selector : null,
};

//

function identitySet( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument.' );
  _.routine.options( identitySet, o );
  _.assert( _.str.defined( o.selector ), 'Expects identity name {-o.selector-}.' );
  _.assert( _.map.is( o.set ), 'Expects map {-o.set-}.' );

  if( !o.force )
  {
    const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
    if( self.identityGet( o2 ) === undefined )
    throw _.err( `Identity ${ o.selector } does not exists.` );
  }

  const o3 = _.mapOnly_( null, o, _.censor.configRead.defaults );
  const config = _.censor.configRead( o3 );

  const o4 = _.mapOnly_( null, o, _.censor.configSet.defaults );
  _.each( o4.set, ( value, key ) =>
  {
    value = _.resolver.resolve
    ({
      src : config,
      selector : value,
      onSelectorReplicate : _.resolver.functor.onSelectorReplicateComposite(),
      onSelectorDown : _.resolver.functor.onSelectorDownComposite(),
    });
    o4.set[ `identity/${ o.selector }/${ key }` ] = value;
    delete o4.set[ key ];
  });

  return _.censor.configSet( o4 );
}

identitySet.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  set : null,
  selector : null,
  force : false,
};

//

function identityNew( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly single options map {-o-}' );
  _.routine.options( identityNew, o );
  _.assert( _.map.is( o.identity ) );
  _.assert( _.str.defined( o.identity.name ), 'Expects field {-o.identity.name-}.' );

  const loginKey = o.identity.type === 'general' || o.identity.type === null ? 'login' : `${ o.identity.type }.login`;
  if( loginKey in o.identity )
  {
    const msg = `Expects defined field {-o.identity[ '${ loginKey }' ]-} or {-o.identity.login-}.`;
    _.assert( _.str.defined( o.identity[ loginKey ] ), msg );
  }
  else
  {
    _.assert( _.str.defined( o.identity.login ), 'Expects field {-o.identity.login-}.' );
  }

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  o2.selector = o.identity.name;
  const identity = self.identityGet( o2 );
  if( !o.force )
  if( identity !== undefined )
  {
    const errMsg = `Identity ${ o.identity.name } already exists. `
    + `Please, delete existed identity or create new identity with different name`;
    throw _.err( errMsg );
  }

  if( o.identity.type === undefined || o.identity.type === null )
  {
    if( !identity || ( identity && !identity.type ) )
    o.identity.type = 'general';
    else
    o.identity.type = identity.type;
  }
  _.assert( _.set.hasKey( self.IdentityTypes, o.identity.type ) || o.identity.type === 'general' );

  o.selector = o.identity.name;
  delete o.identity.name;
  o.set = o.identity;
  delete o.identity;
  o.force = true;

  return self.identitySet( o );
}

identityNew.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  identity : null,
  force : false,
};

//

function identityFrom( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly single options map {-o-}' );
  _.routine.options( identityFrom, o );
  if( o.selector !== null )
  {
    _.assert( _.str.defined( o.selector ) );
    _.assert( !_.path.isGlob( o.selector ) );
  }

  _.censor._configNameMapFromDefaults( o );

  const identityMakerMap =
  {
    git : gitIdentityDataGet,
    npm : npmIdentityDataGet,
    rust : rustIdentityDataGet,
    ssh : sshIdentityDataGet,
  };
  _.assert( o.type in identityMakerMap );

  const ready = _.take( null );
  const start = _.process.starter
  ({
    currentPath : __dirname,
    mode : 'shell',
    outputCollecting : 1,
    outputPiping : 0,
    throwingExitCode : 0,
    inputMirroring : 0,
    sync : 1,
    ready,
  });

  const o3 = _.mapOnly_( null, o, self.identitySet.defaults );
  o3.force = true;
  o3.set = identityMakerMap[ o.type ]();

  if( o3.selector === null )
  o3.selector = o3.set[ `${ o.type }.login` ];

  if( !o.force )
  verifyIdentity( o3.selector );

  if( o.type === 'ssh' )
  {
    const keysRelativePath = _.path.join( o.storageDir, o.profileDir, 'ssh', o3.selector );
    _.fileProvider.filesReflect
    ({
      reflectMap : { [ _.fileProvider.configUserPath( '.ssh') ] : _.fileProvider.configUserPath( keysRelativePath ) }
    });
  }

  return self.identitySet( o3 );

  /* */

  function gitIdentityDataGet()
  {
    const data = Object.create( null );
    data.type = 'git';
    data[ 'git.login' ] = start({ execPath : 'git config --global user.name' }).output.trim();
    data[ 'git.email' ] = start({ execPath : 'git config --global user.email' }).output.trim();
    _.assert( _.str.defined( data[ 'git.login' ] ) );
    _.assert( _.str.defined( data[ 'git.email' ] ) );
    return data;
  }

  /* */

  function npmIdentityDataGet()
  {
    _.assert( false, 'not implemented' );
  }

  /* */

  function rustIdentityDataGet()
  {
    _.assert( false, 'not implemented' );
  }

  /* */

  function sshIdentityDataGet()
  {
    const data = Object.create( null );
    data.type = 'ssh';
    data[ 'ssh.login' ] = o3.selector || 'id_rsa';
    _.assert( _.fileProvider.fileExists( _.fileProvider.configUserPath( '.ssh' ) ), 'Expects ssh keys.' );
    data[ 'ssh.path' ] = _.path.join( o.storageDir, o.profileDir, 'ssh', data[ 'ssh.login' ] );
    return data;
  }

  /* */

  function verifyIdentity( selector )
  {
    const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
    o2.selector = selector;
    const identity = self.identityGet( o2 );
    if( identity !== undefined )
    {
      const errMsg = `Identity ${ selector } already exists. `
      + `Please, delete existed identity or create new identity with different name`;
      throw _.err( errMsg );
    }
  }
}

identityFrom.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  selector : null,
  type : null,
  force : false,
};

//

function identityDel( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );

  if( _.str.is( arguments[ 0 ] ) )
  o = { profileDir : arguments[ 0 ] };
  _.routine.options( identityDel, o );

  _.censor._configNameMapFromDefaults( o );

  if( o.selector === null )
  o.selector = '';
  _.assert( _.str.is( o.selector ) );


  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  const identities = self.identityGet( o2 );

  if( identities )
  if( 'type' in identities )
  {
    if( identities.type === 'ssh' || identities.type === 'general' )
    deleteLocalSshKeys( identities );
  }
  else
  {
    for( let identityKey in identities )
    if( identities[ identityKey ].type === 'ssh' || identities[ identityKey ].type === 'general' )
    deleteLocalSshKeys( identities[ identityKey ] );
  }

  o.selector = `identity/${ o.selector }`;

  _.censor.configDel( o );

  /* */

  function deleteLocalSshKeys( identity )
  {
    const keysRelativePath = _.path.join( o.storageDir, o.profileDir, 'ssh', identity[ 'ssh.login' ] || identity.login );
    _.fileProvider.filesDelete( _.fileProvider.configUserPath( keysRelativePath ) );
  }
}

identityDel.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  selector : null,
};

//

function identityUse( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( identityUse, o );

  _.assert( _.set.hasKey( self.IdentityTypes, o.type ) || o.type === 'general' );
  _.assert( !_.path.isGlob( o.selector ) );

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  const identity = self.identityGet( o2 );
  _.assert( _.map.is( identity ), `Selected no identity : ${ o.identitySrcName }. Please, improve selector.` );
  _.assert
  (
    ( 'login' in identity || `${ o.type }.login` in identity ) && 'type' in identity,
    `Selected ${ _.props.keys( identity ).length } identity(s). Please, improve selector.`
  );
  _.assert( identity.type === 'general' || identity.type === o.type || o.type === null );

  o.type = o.type || identity.type;

  /* */

  let o3 = _.mapOnly_( null, o, self.identityUpdate.defaults );
  self.identityUpdate( _.map.extend( o3, { dst : `_previous.${ o.type }`, deleting : 1, throwing : 0, force : 1 } ) );
  if( o.type === 'ssh' )
  {
    delete o3.dst;
    self.identityUpdate( o3 );
  }

  _.censor.profileHookCallWithIdentity( _.mapOnly_( null, o, _.censor.profileHookCallWithIdentity.defaults ) );
}

identityUse.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  selector : null,
  type : null,
  logger : 2,
};

//

function identityUpdate( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects exactly one argument' );
  _.routine.options( identityUpdate, o );
  _.assert( _.str.defined( o.dst ) || o.dst === null );

  if( o.dst === null )
  {
    const identity = dstIdentityFind();
    if( identity )
    o.dst = identity.login || identity[ `${ o.type }.login` ];
  }

  if( o.dst )
  try
  {
    if( o.deleting )
    self.identityDel({ profileDir : o.profileDir, selector : o.dst });

    const o2 = _.mapOnly_( null, o, self.identityFrom.defaults );
    o2.force = o.force;
    o2.selector = o.dst;
    self.identityFrom( o2 );
  }
  catch( err )
  {
    if( o.throwing )
    throw _.err( err );
    else
    _.error.attend( err );
  }

  /* */

  function dstIdentityFind()
  {
    if( o.type === 'ssh' )
    return sshIdentityFind();
    else
    _.assert( false, 'not implemented' );
  }

  /* */

  function sshIdentityFind()
  {
    const o3 = _.mapOnly_( null, o, self.identityGet.defaults );
    o3.selector = '';
    const identitiesMap = self.identityGet( o3 );

    if( 'type' in identitiesMap )
    {
      if( identitiesMap[ 'ssh.login' ] && identitiesMap[ 'ssh.login' ] !== '_previous.ssh' )
      return checkIdentity( identitiesMap );
    }
    else
    {
      for( let name in identitiesMap )
      {
        const identity = checkIdentity( identitiesMap[ name ] );
        if( identity !== null )
        if( identity[ 'ssh.login' ] && identity[ 'ssh.login' ] !== '_previous.ssh' )
        return identity;
      }
      return null;
    }
  }

  function checkIdentity( identity1 )
  {
    if( identity1.type === 'ssh' )
    if( identity1[ 'ssh.path' ] )
    if( self.identitiesEquivalentAre({ identity1, identity2 : { 'ssh.path' : '.ssh' }, type : 'ssh' }) )
    return identity1;
    return null;
  }
}

identityUpdate.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  dst : null,
  type : null,
  deleting : 0,
  throwing : 1,
  force : 0,
};

//

function identityResolveDefaultMaybe( o )
{
  const self = this;

  _.assert( arguments.length <= 1, 'Expects no arguments or single options map {-o-}.' );

  if( arguments.length === 0 )
  o = Object.create( null );
  else if( _.str.is( o ) )
  o = { profileDir : o };

  _.routine.options( identityResolveDefaultMaybe, o );

  _.assert( _.set.hasKey( self.IdentityTypes, o.type ) || o.type === 'general' || o.type === null );

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  o2.selector = '';
  const identitiesMap = self.identityGet( o2 );

  if( !identitiesMap )
  return null;

  /* */

  let identity = _.any( identitiesMap, ( e ) => e.default ? e : undefined );

  if( o.service )
  {
    if( identity )
    _.assert( !!identity.services || _.longHas( identity.services, o.service ) );
    else
    identity = _.any( identitiesMap, ( e ) => ( !!e.services && _.longHas( e.services, o.service ) ) ? e : undefined );
  }

  if( o.type )
  {
    if( identity )
    _.assert( identity.type === o.type || identity.type === 'general' );
    else
    identity = _.any( identitiesMap, ( e ) => e.type === o.type ? e : undefined );
  }

  return identity;
}

identityResolveDefaultMaybe.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  type : null,
  service : null,
};

//

function identitiesEquivalentAre( o )
{
  const self = this;

  _.assert( arguments.length === 1, 'Expects single options map {-o-}.' );
  _.routine.options( identitiesEquivalentAre, o );

  /* */

  const equalizersMap =
  {
    'git' : equivalentAreSimple,
    'npm' : equivalentAreSimple,
    'rust' : equivalentAreSimple,
    'ssh' : sshIdentitiesEquivalentAre,
  };

  _.assert( o.type in equalizersMap );

  return equalizersMap[ o.type ]( o );

  /* */

  function equivalentAreSimple( o )
  {
    if
    (
      ( o.identity1.type !== o.identity2.type )
      && o.identity1.type !== 'general'
      && o.identity2.type !== 'general'
    )
    return false;

    return _.props.identical( _.mapBut_( null, o.identity1, [ 'type' ] ), _.mapBut_( null, o.identity2, [ 'type' ] ) );
  }

  /* */

  function sshIdentitiesEquivalentAre( o )
  {
    const srcPath1 = o.identity1[ 'ssh.path' ];
    const srcPath2 = o.identity2[ 'ssh.path' ];

    if( srcPath1 === undefined || srcPath2 === undefined )
    return false;
    if( srcPath1 === srcPath2 )
    return true;

    const defaultPrivateKeyName = 'id_rsa';
    const privateKeyPath1 = _.fileProvider.configUserPath( _.path.join( srcPath1, defaultPrivateKeyName ) );
    _.assert( _.fileProvider.fileExists( privateKeyPath1 ), `Expects private key with name "${ defaultPrivateKeyName }"` );
    const privateKeyPath2 = _.fileProvider.configUserPath( _.path.join( srcPath2, defaultPrivateKeyName ) );
    _.assert( _.fileProvider.fileExists( privateKeyPath2 ), `Expects private key with name "${ defaultPrivateKeyName }"` );

    return _.fileProvider.fileRead( privateKeyPath1 ) === _.fileProvider.fileRead( privateKeyPath2 );
  }
}

identitiesEquivalentAre.defaults =
{
  ... _.censor.configNameMapFrom.defaults,
  type : null,
  identity1 : null,
  identity2 : null,
};

// --
// declare
// --

const IdentityTypes = _.set.make([ 'git', 'npm', 'rust', 'ssh' ]);

//

let Extension =
{
  identityCopy,
  identityGet,
  identitySet,
  identityNew,
  identityFrom,
  identityDel,
  identityUse,
  identityUpdate,
  identityResolveDefaultMaybe,
  identitiesEquivalentAre,

  IdentityTypes,
};

Object.assign( _.identity, Extension );

//

if( typeof module !== 'undefined' )
module[ 'exports' ] = _global_.wTools;

})();
