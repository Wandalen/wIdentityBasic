( function _Identity_s_()
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
    ( 'login' in identity || `${ identity.type }.login` in identity || 'identities' in identity ) && 'type' in identity,
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

  return _.censor.configGet( _.aux.extend( null, o ) );
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
  _.assert( _.set.hasKey( self.IdentityTypes, o.identity.type ) || o.identity.type === 'super' );

  if( o.identity.type === 'super' )
  {
    _.assert( 'identities' in o.identity );
  }
  else
  {
    const msg = `Expects defined field {-o.identity[ '${ o.identity.type }.login' ]-} or {-o.identity.login-}.`;
    _.assert( _.str.defined( o.identity[ 'login' ] ) || _.str.defined( o.identity[ `${ o.identity.type }.login` ] ), msg );
  }

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  o2.selector = o.identity.name;

  if( !o.force )
  {
    const identity = self.identityGet( o2 );
    if( identity !== undefined )
    {
      const errMsg = `Identity ${ o.identity.name } already exists. `
      + `Please, delete existed identity or create new identity with different name`;
      throw _.err( errMsg );
    }
  }

  if( o.identity.type === 'super' && !_.aux.is( o.identity.identities ) )
  {
    const identities = Object.create( null );

    if( _.str.is( o.identity.identities ) )
    {
      identities[ o.identity.identities ] = true;
    }
    else if( _.array.is( o.identity.identities ) )
    {
      for( let i = 0 ; i < o.identity.identities.length ; i++ )
      {
        _.assert( _.str.defined( o.identity.identities[ i ] ) );
        identities[ o.identity.identities[ i ] ] = true;
      }
    }
    else
    {
      _.assert( false, 'Expects identities list as string, array or map.' );
    }

    o.identity.identities = identities;
  }

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
    if( identities.type === 'ssh' )
    deleteLocalSshKeys( identities );
  }
  else
  {
    for( let identityKey in identities )
    if( identities[ identityKey ].type === 'ssh' )
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

  _.assert( _.set.hasKey( self.IdentityTypes, o.type ) || o.type === 'super' );
  _.assert( !_.path.isGlob( o.selector ) );

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  const identity = self.identityGet( o2 );
  _.assert( _.map.is( identity ), `Selected no identity : ${ o.identitySrcName }. Please, improve selector.` );
  _.assert
  (
    ( 'login' in identity || `${ o.type }.login` in identity || 'identities' in identity ) && 'type' in identity,
    `Selected ${ _.props.keys( identity ).length } identity(s). Please, improve selector.`
  );
  _.assert( identity.type === 'super' || identity.type === o.type );

  /* */

  const o3 = _.mapOnly_( null, o, self.identityUpdate.defaults );
  if( identity.type === 'super' )
  {
    if( o.type === 'super' )
    {
      const o4 = _.mapOnly_( null, o, self.identityGet.defaults );
      for( let key in identity.identities )
      if( identity.identities[ key ] )
      {
        o4.selector = key;
        const identity2 = _.identity.identityGet( o4 );
        identityUpdateByType( identity2.type );
        o.identity = identity2;
        _.censor.profileHookCallWithIdentity( _.mapOnly_( null, o, _.censor.profileHookCallWithIdentity.defaults ) );
      }
    }
    else
    {
      const o4 = _.mapOnly_( null, o, self.identityGet.defaults );
      for( let key in identity.identities )
      if( identity.identities[ key ] )
      {
        o4.selector = key;
        const identity2 = _.identity.identityGet( o4 );
        if( identity2.type === o.type )
        {
          identityUpdateByType( o.type );
          o.identity = identity2;
          _.censor.profileHookCallWithIdentity( _.mapOnly_( null, o, _.censor.profileHookCallWithIdentity.defaults ) );
          break;
        }
      }
    }
  }
  else
  {
    identityUpdateByType( o.type );
    o.identity = identity;
    _.censor.profileHookCallWithIdentity( _.mapOnly_( null, o, _.censor.profileHookCallWithIdentity.defaults ) );
  }

  /* */

  function identityUpdateByType( type )
  {
    self.identityUpdate( _.map.extend( o3, { dst : `_previous.${ type }`, deleting : 1, throwing : 0, force : 1 } ) );
    if( type === 'ssh' )
    {
      delete o3.dst;
      self.identityUpdate( o3 );
    }
  }
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
  _.assert( _.set.hasKey( self.IdentityTypes, o.type ) || o.type === 'super' || o.type === null );

  _.censor._configNameMapFromDefaults( o );

  const o2 = _.mapOnly_( null, o, self.identityGet.defaults );
  o2.selector = '';
  const identitiesMap = self.identityGet( o2 );

  if( !identitiesMap )
  return null;

  /* */


  const identities = [];
  _.each( identitiesMap, ( e ) => e.default ? identities.push( e ) : undefined );

  if( o.service )
  {
    if( identities.length > 0 )
    {
      for( let i = identities.length - 1 ; i >= 0 ; i-- )
      if( ( identities[ i ].services && !_.longHas( identities[ i ].services, o.service ) ) || !identities[ i ].services )
      identities.splice( i, 1 );
    }
    else
    {
      _.each( identitiesMap, ( e ) => ( !!e.services && _.longHas( e.services, o.service ) ) ? identities.push( e ) : undefined );
    }
  }

  if( o.type )
  {
    if( identities.length > 0 )
    for( let i = identities.length - 1 ; i >= 0 ; i-- )
    {
      if( identities[ i ].type === 'super' )
      {
        for( let key in identities[ i ].identities )
        if( identitiesMap[ key ] && identitiesMap[ key ].type === o.type )
        {
          identities[ i ] = identitiesMap[ key ];
          break;
        }
        else
        {
          delete identities[ i ].identities[ key ];
        }
        if( identities[ i ].identities && _.map.keys( identities[ i ].identities ).length === 0 )
        identities.splice( i, 1 )
      }
      else
      {
        if( identities[ i ].type !== o.type )
        identities.splice( i, 1 );
      }
    }
    else
    {
      _.each( identitiesMap, ( e ) => e.type === o.type ? identities.push( e ): undefined );
    }
  }

  _.arrayRemoveDuplicates( identities );
  _.assert
  (
    identities.length <= 1,
    () => `Got ${ identities.length } identities. Please, improve filters {-type-} and {-service-} to select single identity`
  );

  return identities[ 0 ];
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
      && o.identity1.type !== 'super'
      && o.identity2.type !== 'super'
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

const IdentityTypes = _.set.make
([
  'git',
  'github',
  'bitbucket',
  'npm',
  'cargo',
  'ssh',
]);

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
